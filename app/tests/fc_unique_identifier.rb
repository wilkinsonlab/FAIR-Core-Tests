require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest


  def self.fc_unique_identifier_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname: "FAIR Champion: Unique Identifier",
    testid: "fc_unique_identifier",
    description: "Metric to test if the metadata resource has a unique identifier.  This is done by comparing the GUID to the patterns (by regexp) of known GUID schemas such as URLs and DOIs.  Known schema are registered in FAIRSharing (https://fairsharing.org/standards/?q=&selected_facets=type_exact:identifier%20schema)",
    metric: 'https://purl.org/fair-metrics/Gen2_FM_F1A',
    principle: "F1"
    }
  end

  def self.fc_unique_identifier(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_unique_identifier_meta[:testid], 
      name: self.fc_unique_identifier_meta[:testname], 
      version: self.fc_unique_identifier_meta[:testversion],
      description: self.fc_unique_identifier_meta[:description], 
      metric:self.fc_unique_identifier_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{self.fc_unique_identifier_meta[:testversion]}'\n"

    type = FAIRChampion::Harvester.typeit(guid) # this is where the magic happens!

    unless type
      output.score = "indeterminate"
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known globally unique identitier system.\n"
      return output.createEvaluationResponse
    end

    # hash = metadata.hash
    # graph = metadata.graph
    # properties = FAIRChampion::Harvester.deep_dive_properties(hash)
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
    output.comments << "SUCCESS: Found an identifier of type '#{type}'\n"
    output.score = "pass"
    return output.createEvaluationResponse
  end

  
  def self.fc_unique_identifier_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(      title: self.fc_unique_identifier_meta[:testname],
                            description: self.fc_unique_identifier_meta[:description],
                            tests_metric: self.fc_unique_identifier_meta[:metric],
                            version: self.fc_unique_identifier_meta[:testversion],
                            applies_to_principle: self.fc_unique_identifier_meta[:principle],
                            organization: 'OSTrails Project',
                            org_url: 'https://ostrails.eu/',
                            responsible_developer: 'Mark D Wilkinson',
                            email: 'mark.wilkinson@upm.es',
                            developer_ORCiD: '0000-0001-6960-357X',
                            protocol: ENV.fetch('TEST_PROTOCOL', nil),
                            host: ENV.fetch('TEST_HOST', nil),
                            basePath: ENV.fetch('TEST_PATH', nil),
                            path: self.fc_unique_identifier_meta[:testid],
                            response_description: 'The response is "pass", "fail" or "indeterminate"',
                            schemas: schemas,
                          )

    api.get_api
  end
end