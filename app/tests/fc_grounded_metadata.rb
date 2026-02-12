require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_grounded_metadata_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Grounded Metadata',
      testid: 'fc_grounded_metadata',
      description: "Tests whether a machine is able to find 'grounded' metadata.  i.e. metadata terms that are in a resolvable namespace, where resolution leads to a definition of the meaning of the term. Examples include JSON-LD, embedded schema, or any form of RDF. This test currently excludes XML, even when terms are namespaced.  Future versions of this test may be more flexible.",
      metric: 'https://w3id.org/fair-metrics/general/Gen2-MI-F2'.downcase,
      indicators: 'https://doi.org/10.25504/FAIRsharing.e05e98',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'FAIR Principles'],
      themes: ['http://edamontology.org/topic_4012'],
      organization: 'OSTrails Project',
      org_url: 'https://ostrails.eu/',
      responsible_developer: 'Mark D Wilkinson',
      email: 'mark.wilkinson@upm.es',
      response_description: 'The response is "pass", "fail" or "indeterminate"',
      schemas: { 'subject' => ['string', 'the GUID being tested'] },
      organizations: [{ 'name' => 'OSTrails Project', 'url' => 'https://ostrails.eu/' }],
      individuals: [{ 'name' => 'Mark D Wilkinson', 'email' => 'mark.wilkinson@upm.es' }],
      creator: 'https://orcid.org/0000-0001-6960-357X',
      protocol: ENV.fetch('TEST_PROTOCOL', 'https'),
      host: ENV.fetch('TEST_HOST', 'localhost'),
      basePath: ENV.fetch('TEST_PATH', '/tests')
    }
  end

  def self.fc_grounded_metadata(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_grounded_metadata_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_grounded_metadata_meta[:testversion]}'\n"

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

    if graph.size > 0 # have we found anything yet?
      output.score = 'pass'
      output.comments << "SUCCESS: found linked-data style structured metadata.\n"
    else
      output.comments << "FAILURE: no linked-data style structured metadata found.\n"
      output.score = 'fail'
    end
    output.createEvaluationResponse
  end

  def self.fc_grounded_metadata_api
    api = OpenAPI.new(meta: fc_grounded_metadata_meta)
    api.get_api
  end

  def self.fc_grounded_metadata_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_grounded_metadata_meta)
    dcat.get_dcat
  end
end
