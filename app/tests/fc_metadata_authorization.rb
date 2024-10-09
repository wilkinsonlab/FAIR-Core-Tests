require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_authorization_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Authorization',
      testid: 'fc_metadata_authorization',
      description: "Tests metadata GUID for the ability to implement authentication and authorization in its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.",
      metric: 'https://doi.org/10.25504/FAIRsharing.VrP6sm',
      principle: 'https://w3id.org/fair/principles/latest/A1.2',
      type: "http://edamontology.org/operation_2428",
      license: "https://creativecommons.org/publicdomain/zero/1.0/",
      keywords: ["FAIR Assessment", "FAIR Principles"],
      themes: ['http://edamontology.org/topic_4012']
    }
  end

  def self.fc_metadata_authorization(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_metadata_authorization_meta[:testid], 
      name: fc_metadata_authorization_meta[:testname],
      version: fc_metadata_authorization_meta[:testversion],
      description: fc_metadata_authorization_meta[:description],
      metric: fc_metadata_authorization_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_authorization_meta[:testversion]}'\n"


    type = FAIRChampion::Harvester.typeit(guid) # this is where the magic happens!

    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    if !type
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The GUID identifier of the metadata #{guid} did not match any known identification system.\n"
    else
      output.comments << "PASS:  The GUID of the metadata is a #{type}, which is known to be allow authentication/authorization.\n"
      output.score = 'pass'
    end
    output.createEvaluationResponse
  end

  def self.fc_metadata_authorization_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(title: fc_metadata_authorization_meta[:testname],
                      descriptions: fc_metadata_authorization_meta[:description],
                      tests_metric: fc_metadata_authorization_meta[:metric],
                      version: fc_metadata_authorization_meta[:testversion],
                      applies_to_principle: fc_metadata_authorization_meta[:principle],
                      path: fc_metadata_authorization_meta[:testid],
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


  def self.fc_metadata_authorization_about     
    protocol = ENV.fetch('TEST_PROTOCOL', "http")
    host = ENV.fetch('TEST_HOST', "localhost")
    basePath = ENV.fetch('TEST_PATH', "/test")

    end_url = "#{protocol}://#{host}/basePath/#{fc_metadata_authorization_meta[:testid]}"
    end_desc = "#{protocol}://#{host}/basePath/#{fc_metadata_authorization_meta[:testid]}"

  dcat = ChampionDCAT::DCAT_Record.new(
                      title: fc_metadata_authorization_meta[:testname],
                      descriptions: [fc_metadata_authorization_meta[:description]],
                      implementations: [fc_metadata_authorization_meta[:metric]],
                      version: fc_metadata_authorization_meta[:testversion],
                      indicators: [fc_metadata_authorization_meta[:principle]],
                      # i = {name: "CBGP", "url": "https://dbdsf.orhf"}
                      organizations: [{"name" =>'OSTrails Project', "url" => 'https://ostrails.eu/'}],
                      # i = {name: "Mark WAilkkinson", "email": "asmlkfj;askjf@a;lksdjfas"}
                      individuals: [{"name" => 'Mark D Wilkinson', "email" =>'mark.wilkinson@upm.es'}],
                      creator: 'https://orcid.org/0000-0001-6960-357X',
                      end_desc: end_desc, 
                      end_url: end_url,
                      dctype: fc_metadata_authorization_meta[:type],
                      license: fc_metadata_authorization_meta[:license],
                      themes: fc_metadata_authorization_meta[:themes],
                      keywords: fc_metadata_authorization_meta[:keywords],
                      identifier: end_url,
                      )

    dcat.get_dcat
  end

end
