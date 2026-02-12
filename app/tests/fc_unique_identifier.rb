require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_unique_identifier_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.1',
      testname: 'FAIR Champion: Unique Identifier',
      testid: 'fc_unique_identifier',
      description: 'Metric to test if the metadata resource has a unique identifier.  This is done by comparing the GUID to the patterns (by regexp) of known GUID schemas such as URLs and DOIs.  Known schema are registered in FAIRSharing (https://fairsharing.org/standards/?q=&selected_facets=type_exact:identifier%20schema)',
      metric: 'https://w3id.org/fair-metrics/general/Gen2-MI-F1'.downcase,
      indicators: 'https://doi.org/10.25504/FAIRsharing.b7f1ab',
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
      basePath: ENV.fetch('TEST_PATH', '/tests'),
      guidance: [['urn:cat_graph:gdn.49738A73',
                  'You should be using a globally unique persistent identifier like a purl, ark, doi, or w3id']]
    }
  end

  def self.fc_unique_identifier(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_unique_identifier_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_unique_identifier_meta[:testversion]}'\n"

    type = FAIRChampion::Harvester.typeit(guid) # this is where the magic happens!

    unless type
      output.score = 'indeterminate'
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
    output.score = 'pass'
    output.createEvaluationResponse
  end

  def self.fc_unique_identifier_api
    api = OpenAPI.new(meta: fc_unique_identifier_meta)
    api.get_api
  end

  def self.fc_unique_identifier_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_unique_identifier_meta)
    dcat.get_dcat
  end
end
