require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest
  def self.fc_metadata_kr_language_strong_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Knowledge Representation Language (strong)',
      testid: 'fc_metadata_includes_license_weak',
      description: "Maturity Indicator to test if the metadata uses a formal language broadly applicable for knowledge representation.  This particular test takes a broad view of what defines a 'knowledge representation language'; in this evaluation, a knowledge representation language is interpreted as one in which terms are semantically-grounded in ontologies.  Any form of RDF will pass this test (including RDF that is automatically extracted by third-party parsers such as Apache Tika).",
      metric: 'https://purl.org/fair-metrics/Gen2_FM_I1B',
      principle: 'I1'
    }
  end

  def self.fc_metadata_kr_language_strong(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_metadata_kr_language_strong_meta[:testid], 
      name: fc_metadata_kr_language_strong_meta[:testname],
      version: fc_metadata_kr_language_strong_meta[:testversion],
      description: fc_metadata_kr_language_strong_meta[:description],
      metric: fc_metadata_kr_language_strong_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_kr_language_strong_meta[:testversion]}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
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

    if graph.size > 0  # have we found anything yet?
      output.comments << "SUCCESS: Linked data was found.  "
      output.score = "pass"
    else
      output.comments << "FAILURE: No linked data was found.  "
      output.score = "fail"
    end
  
    output.createEvaluationResponse
  end

  def self.fc_metadata_kr_language_strong_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(title: fc_metadata_kr_language_strong_meta[:testname],
                      description: fc_metadata_kr_language_strong_meta[:description],
                      tests_metric: fc_metadata_kr_language_strong_meta[:metric],
                      version: fc_metadata_kr_language_strong_meta[:testversion],
                      applies_to_principle: fc_metadata_kr_language_strong_meta[:principle],
                      path: fc_metadata_kr_language_strong_meta[:testid],
                      organization: 'OSTrails Project',
                      org_url: 'https://ostrails.eu/',
                      responsible_developer: 'Mark D Wilkinson',
                      email: 'mark.wilkinson@upm.es',
                      developer_ORCiD: '0000-0001-6960-357X',
                      protocol: ENV.fetch('TEST_PROTOCOL', nil),
                      host: ENV.fetch('TEST_HOST', nil),
                      basePath: ENV.fetch('TEST_PATH', nil),
                      response_description: 'The response is "pass", "fail" or "indeterminate"',
                      schemas: schemas)

    api.get_api
  end
end
