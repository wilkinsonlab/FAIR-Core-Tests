require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest

  def self.fc_metadata_protocol_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname: "FAIR Champion: Uses open free protocol for metadata retrieval",
    testid: "fc_metadata_protocol",
    description: "Metadata may be retrieved by an open and free protocol.  Tests metadata GUID for its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.",
    metric: 'https://purl.org/fair-metrics/Gen2_FM_A1.1',
    principle: "A1.1"
    }
  end

  def self.fc_metadata_protocol(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: self.fc_metadata_protocol_meta[:testname], 
      version: self.fc_metadata_protocol_meta[:testversion],
      description: self.fc_metadata_protocol_meta[:description], 
      metric:self.fc_metadata_protocol_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{self.fc_metadata_protocol_meta[:testversion]}'\n"

    type = FAIRChampion::Harvester.typeit(guid) # this is where the magic happens!


  

    # hash = metadata.hash
    # graph = metadata.graph
    # properties = FAIRChampion::Harvester.deep_dive_properties(hash)
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
    unless type
      output.score = "indeterminate"
      output. comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    else
      output.score = "pass"
      output.comments << "SUCCESS: The identifier #{guid} is of type #{type}, which is resolvable by an open protocol."
      return output.createEvaluationResponse
    end
  end

  
  def self.fc_metadata_protocol_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(      title: self.fc_metadata_protocol_meta[:testname],
                            description: self.fc_metadata_protocol_meta[:description],
                            tests_metric: self.fc_metadata_protocol_meta[:metric],
                            version: self.fc_metadata_protocol_meta[:testversion],
                            applies_to_principle: self.fc_metadata_protocol_meta[:principle],
                            organization: 'OSTrails Project',
                            org_url: 'https://ostrails.eu/',
                            responsible_developer: 'Mark D Wilkinson',
                            email: 'mark.wilkinson@upm.es',
                            developer_ORCiD: '0000-0001-6960-357X',
                            protocol: ENV.fetch('TEST_PROTOCOL', nil),
                            host: ENV.fetch('TEST_HOST', nil),
                            basePath: ENV.fetch('TEST_PATH', nil),
                            path: self.fc_metadata_protocol_meta[:testid],
                            response_description: 'The response is "pass", "fail" or "indeterminate"',
                            schemas: schemas,
                          )

    api.get_api
  end
end