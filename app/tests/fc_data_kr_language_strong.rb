require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'



class FAIRTest

  def self.fc_data_kr_language_strong_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname: "FAIR Champion: Data Knowlege Representation Language (Strict Test)",
    testid: "fc_data_kr_language_strong",
    description: "Test if the data uses a formal language broadly applicable for knowledge representation.  This particular test takes a broad view of what defines a 'knowledge representation language'; in this evaluation, a knowledge representation language is interpreted as one in which terms are semantically-grounded in ontologies.  Any form of ontologically-grounded linked data will pass this test. ",
    metric: 'https://purl.org/fair-metrics/Gen2_FM_I1B',
    principle: "I1"
    }
  end


  def self.fc_data_kr_language_strong(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: self.fc_data_kr_language_strong_meta[:testname], 
      version: self.fc_data_kr_language_strong_meta[:testversion],
      description: self.fc_data_kr_language_strong_meta[:description], 
      metric:self.fc_data_kr_language_strong_meta[:metric]
    )
    output.comments << "INFO: TEST VERSION '#{self.fc_data_kr_language_strong_meta[:testversion]}'\n"

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
        output.comments <<  "INFO: Now resolving #{identifier} to test its properties.\n"
        self.testIdentifier(guid: identifier, output: output) # this will add more comments and a score to output
    end
    return output.createEvaluationResponse
  end

  def self.testIdentifier(guid:, output: )
	
    type, url = FAIRChampion::Harvester::convertToURL(guid)
    if url.nil?
      output.comments << "INDETERMINATE: The GUID identifier of the data #{guid} did not match any known identification system (tested inchi, doi, handle, uri) and therefore did not pass this metric.  If you think this is an error, please contact the FAIR Metrics group (http://fairmetrics.org)."
      output.score = "indeterminate"
      return
    end
  
    if type == "handle"
      output.comments << "INFO: The GUID of the data is a Handle.\n"
    elsif type == "doi"
      output.comments << "INFO: The GUID of the data is a DOI.\n"
    elsif type == "inchi"
      output.comments << "INFO: The GUID of the data is a InChI.\n"
    elsif type == "uri"
      output.comments << "INFO: The GUID of the data appears to be a URI/URL.\n"
    else
      output.comments << "INFO: The GUID of the data could not be typed, therefore it cannot be tested.\n"
      output.score = "indeterminate"
      return
    end
    headers = FAIRChampion::Harvester::head(url, FAIRChampion::Utils::AcceptHeader) # returns headers or false
    if headers
      if headers.keys.include?(:content_type)
        type = headers[:content_type]
        rdfformats = FAIRChampion::Utils::RDF_FORMATS.values.flatten
        if rdfformats.include?(type)
          output.comments << "SUCCESS: The reported content-type of the data is [#{type}] which is a known Linked Data format\n"
          output.score = "pass"
          return
        else 
          output.comments << "FAILURE: The reported content-type of the data is [#{type}] which is not a known Linked Data format\n"
          output.score = "fail"
          return
        end
      else
        output.comments << "INDETERMINATE: The URL to the data is not reporting a Content-Type in its headers.  This test will now halt.\n"
        output.score = "indeterminate"
        return
      end
    else
      output.comments << "INDETERMINATE: The url #{url} failed to resolve via a HEAD call with headers #{FAIRChampion::Utils::AcceptHeader}, therefore we cannot continue\n"
      output.score = "indeterminate"
      return
    end
  end

  
  def self.fc_data_kr_language_strong_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(      title: self.fc_data_kr_language_strong_meta[:testname],
                            description: self.fc_data_kr_language_strong_meta[:description],
                            tests_metric: self.fc_data_kr_language_strong_meta[:metric],
                            version: self.fc_data_kr_language_strong_meta[:testversion],
                            applies_to_principle: self.fc_data_kr_language_strong_meta[:principle],
                            organization: 'OSTrails Project',
                            org_url: 'https://ostrails.eu/',
                            responsible_developer: 'Mark D Wilkinson',
                            email: 'mark.wilkinson@upm.es',
                            developer_ORCiD: '0000-0001-6960-357X',
                            protocol: ENV.fetch('TEST_PROTOCOL', nil),
                            host: ENV.fetch('TEST_HOST', nil),
                            basePath: ENV.fetch('TEST_PATH', nil),
                            path: self.fc_data_kr_language_strong_meta[:testid],
                            response_description: 'The response is "pass", "fail" or "indeterminate"',
                            schemas: schemas,
                          )

    api.get_api
  end
end