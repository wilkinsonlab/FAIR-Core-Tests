require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest

  def self.fc_data_identifier_in_metadata_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname: "FAIR Champion: Data Identifier in Metadata",
    testid: "fc_data_identifier_in_metadata",
    description: "Test a discovered data GUID for the ability to implement authentication and authorization in its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  It also searches the metadata for the Dublin Core 'accessRights' property, which may point to a document describing the data access process. Recognition of other identifiers will be added upon request by the community.",
    metric: 'https://purl.org/fair-metrics/Gen2_FM_F3',
    principle: "F3"
    }
  end

  def self.fc_data_identifier_in_metadata(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: self.fc_data_identifier_in_metadata_meta[:testname], 
      version: self.fc_data_identifier_in_metadata_meta[:testversion],
      description: self.fc_data_identifier_in_metadata_meta[:description], 
      metric:self.fc_data_identifier_in_metadata_meta[:metric]
    )
    output.comments << "INFO: TEST VERSION '#{self.fc_data_identifier_in_metadata_meta[:testversion]}'\n"

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
        output.score = "fail"
        output.comments <<  "INFO: Tested the following #{FAIRChampion::Utils::DATA_PREDICATES}(or their plain JSON hash-key equivalents)\n"
        output.comments <<  "FAILURE: Was unable to locate the data identifier in the metadata using any (common) property/predicate reserved for this purpose."
    else
        output.comments <<  "INFO: Now resolving #{identifier} to test its properties.\n"
        self.testIdentifier(guid: identifier, output: output) # this will add more comments and a score to @swagger
    end
    return output.createEvaluationResponse
  end


  def self.testIdentifier(guid:, output:)

    # This is verbatim from the gen2_metadata_identifier_persistence
    type = FAIRChampion::Harvester::typeit(guid)  # this is where the magic happens!

    output.comments << "INFO: The data guid (#{guid}) is detected as a #{type}.\n"

    if !type
      output.comments << "FAILURE: The GUID identifier of the data #{guid} did not match any known identification system.\n"
      output.score = "fail"
    elsif type == "uri"
      output.comments << "INFO: The data GUID appears to be a URL.  Testing known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark, doi(as URL)).\n"
      if (guid =~ /(purl)\./) or (guid =~ /(oclc)\./) or(guid =~ /(fdlp)\./) or (guid =~ /(purlz)\./) or (guid =~ /(w3id)\./) or (guid =~ /(ark)\:/) or (guid =~ /(doi.org)/)
        output.comments << "SUCCESS: The GUID conforms with #{$1}, which is known to be persistent.\n"
        output.score = "pass"
      else
        output.comments << "FAILURE: The GUID does not conform with any known permanent-URL system.\n"
        output.score = "fail"
      end
    else 
      output.comments << "SUCCESS: The GUID of the data is a #{type}, which is known to be persistent.\n"
      output.score = "pass"
    end


  end

  def self.fc_data_identifier_in_metadata_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(      title: self.fc_data_identifier_in_metadata_meta[:testname],
                            description: self.fc_data_identifier_in_metadata_meta[:description],
                            tests_metric: self.fc_data_identifier_in_metadata_meta[:metric],
                            version: self.fc_data_identifier_in_metadata_meta[:testversion],
                            applies_to_principle: self.fc_data_identifier_in_metadata_meta[:principle],
                            organization: 'OSTrails Project',
                            org_url: 'https://ostrails.eu/',
                            responsible_developer: 'Mark D Wilkinson',
                            email: 'mark.wilkinson@upm.es',
                            developer_ORCiD: '0000-0001-6960-357X',
                            protocol: ENV.fetch('TEST_PROTOCOL', nil),
                            host: ENV.fetch('TEST_HOST', nil),
                            basePath: ENV.fetch('TEST_PATH', nil),
                            path: self.fc_data_identifier_in_metadata_meta[:testid],
                            response_description: 'The response is "pass", "fail" or "indeterminate"',
                            schemas: schemas,
                          )

    api.get_api
  end
end