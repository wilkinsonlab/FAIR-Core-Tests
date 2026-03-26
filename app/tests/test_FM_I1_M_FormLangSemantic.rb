require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.test_FM_I1_M_FormLangSemantic_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.0',
      testname: 'OSTrails Core: Metadata Knowledge Representation Language is Semantically Grounded',
      testid: 'test_FM_I1_M_FormLangSemantic',
      description: "Maturity Indicator to test if the metadata uses a formal language broadly
      applicable for knowledge representation.  This particular test takes a broad view of what defines
      a 'knowledge representation language'; in this evaluation, a knowledge representation
      language is interpreted as one in which terms are semantically-grounded in ontologies.
      Any form of RDF will pass this test (including RDF that is automatically extracted by
      third-party parsers such as Apache Tika).",
      metric: 'https://w3id.org/fair-metrics/general/FM_I1_M_FormLangSemantic',
      indicators: 'https://doi.org/10.25504/FAIRsharing.ec5648',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'FAIR Principles'],
      themes: ['http://edamontology.org/topic_4012'],
      organization: 'OSTrails Project',
      org_url: 'https://ostrails.eu/',
      responsible_developer: 'Mark D Wilkinson',
      email: 'mark.wilkinson@upm.es',
      response_description: 'The response is "pass", "fail" or "indeterminate"',
      schemas: { 'resource_identifier' => ['string', 'the GUID being tested'] },
      organizations: [{ 'name' => 'OSTrails Project', 'url' => 'https://ostrails.eu/' }],
      individuals: [{ 'name' => 'Mark D Wilkinson', 'email' => 'mark.wilkinson@upm.es' }],
      creator: 'https://orcid.org/0000-0001-6960-357X',
      protocol: ENV.fetch('TEST_PROTOCOL', 'https'),
      host: ENV.fetch('TEST_HOST', 'localhost'),
      basePath: ENV.fetch('TEST_PATH', '/tests')
    }
  end

  def self.test_FM_I1_M_FormLangSemantic(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: test_FM_I1_M_FormLangSemantic_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_I1_M_FormLangSemantic_meta[:testversion]}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    _hash = metadata.hash
    graph = metadata.graph
    # properties = FAIRChampion::Harvester.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    if graph.size > 0 # have we found anything yet?
      output.comments << 'SUCCESS: Linked data was found.  '
      output.score = 'pass'
    else
      output.comments << 'FAILURE: No linked data was found.  '
      output.score = 'fail'
    end

    output.createEvaluationResponse
  end

  def self.test_FM_I1_M_FormLangSemantic_api
    api = OpenAPI.new(meta: test_FM_I1_M_FormLangSemantic_meta)
    api.get_api
  end

  def self.test_FM_I1_M_FormLangSemantic_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: test_FM_I1_M_FormLangSemantic_meta)
    dcat.get_dcat
  end
end
