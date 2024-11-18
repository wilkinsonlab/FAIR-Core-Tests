require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_authorization_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Authorization',
      testid: 'fc_metadata_authorization',
      description: 'Tests metadata GUID for the ability to implement authentication and authorization in its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.',
      metric: 'https://doi.org/10.25504/FAIRsharing.VrP6sm',
      principle: 'https://w3id.org/fair/principles/latest/A1.2',
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
      basePath: ENV.fetch('TEST_PATH', '/test')
    }
  end

  def self.fc_metadata_authorization(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(testedGUID: guid, metadata: fc_metadata_authorization_meta)

    output.comments << "INFO: TEST VERSION '#{fc_metadata_authorization_meta[:testversion]}'\n"

    type = FAIRChampion::Harvester.typeit(guid) # this is where the magic happens!

    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    if type
      output.comments << "PASS:  The GUID of the metadata is a #{type}, which is known to be allow authentication/authorization.\n"
      output.score = 'pass'
    else
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The GUID identifier of the metadata #{guid} did not match any known identification system.\n"
    end
    output.createEvaluationResponse
  end

  def self.fc_metadata_authorization_api
    api = OpenAPI.new(meta: fc_metadata_authorization_meta)
    api.get_api
  end

  def self.fc_metadata_authorization_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_metadata_authorization_meta)
    dcat.get_dcat
  end
end
