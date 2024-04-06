require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest

  def self.fc_data_protocol_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname: "FAIR Champion: Data Protocol",
    testid: "fc_data_protocol",
    description: "Data may be retrieved by an open and free protocol.  Tests data GUID for its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.",
    metric: 'https://purl.org/fair-metrics/Gen2_FM_A1.1',
    principle: "A1.1"
    }
  end


  def self.fc_data_protocol(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_data_protocol_meta[:testid], 
      name: self.fc_data_protocol_meta[:testname], 
      version: self.fc_data_protocol_meta[:testversion],
      description: self.fc_data_protocol_meta[:description], 
      metric:self.fc_data_protocol_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{self.fc_data_protocol_meta[:testversion]}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = "indeterminate"
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    hash = metadata.hash
    graph = metadata.graph
    properties = FAIRChampion::Harvester.deep_dive_properties(hash)
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################


    output.comments << "INFO: Searching metadata for likely identifiers to the data record\n"
    identifier = nil

    properties.each do |keyval|
      key, value = nil, nil
      (key, value) = keyval;
      key = key.to_s
      
      output.comments << "INFO: Searching hash-style metadata for keys indicating a pointer to data.\n"
      FAIRChampion::Utils::DATA_PREDICATES.each do |prop|
        prop =~ /.*[#\/]([^#\/]+)$/
        prop = $1
        output.comments << "INFO: Searching for key: #{prop}.\n"
        if key == prop
          output.comments << "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
          identifier=value.to_s
        end
      end
    end


    if graph.size > 0  # have we found anything yet?
      output.comments << "INFO: Searching Linked Data metadata for predicates indicating a pointer to data.\n"
      identifier = FAIRChampion::CommonQueries::GetDataIdentifier(graph: graph)		
    end

    unless identifier =~ /\w+/
        output.score = "indeterminate"
        output.comments <<  "INFO: Tested the following #{FAIRChampion::Utils::DATA_PREDICATES}(or their plain JSON hash-key equivalents)\n"
        output.comments <<  "INDETERMINATE: Was unable to locate the data identifier in the metadata using any (common) property/predicate reserved for this purpose."
    else
        metadata2 = FAIRChampion::Harvester::typeit(identifier) 
        if !metadata2
          output.comments <<  "FAILURE: The identifier #{@identifier} did not match any known identification system.\n"
          output.score = "fail"
        else
          output.comments <<  "SUCCESS: The identifier #{@identifier} is recognized as a #{metadata2}, which is resolvable by an open and free protocol.\n"
          output.score = "pass"
        end
    end
    return output.createEvaluationResponse

  end

  
  def self.fc_data_protocol_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(      title: self.fc_data_protocol_meta[:testname],
                            description: self.fc_data_protocol_meta[:description],
                            tests_metric: self.fc_data_protocol_meta[:metric],
                            version: self.fc_data_protocol_meta[:testversion],
                            applies_to_principle: self.fc_data_protocol_meta[:principle],
                            organization: 'OSTrails Project',
                            org_url: 'https://ostrails.eu/',
                            responsible_developer: 'Mark D Wilkinson',
                            email: 'mark.wilkinson@upm.es',
                            developer_ORCiD: '0000-0001-6960-357X',
                            protocol: ENV.fetch('TEST_PROTOCOL', nil),
                            host: ENV.fetch('TEST_HOST', nil),
                            basePath: ENV.fetch('TEST_PATH', nil),
                            path: self.fc_data_protocol_meta[:testid],
                            response_description: 'The response is "pass", "fail" or "indeterminate"',
                            schemas: schemas,
                          )

    api.get_api
  end
end