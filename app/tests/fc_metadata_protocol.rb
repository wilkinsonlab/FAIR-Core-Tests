require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest

  def self.fc_metadata_protocol_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname: "FAIR Champion: Uses open free protocol for metadata retrieval",
    testid: "fc_metadata_protocol",
    description: "Metadata may be retrieved by an open and free protocol.  Tests metadata GUID for its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.",
    metric: 'https://doi.org/10.25504/FAIRsharing.yDJci5',
    indicators: 'https://w3id.org/fair/principles/latest/A1.1',
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

  def self.fc_metadata_protocol(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_metadata_protocol_meta[:testid], 
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
    api = OpenAPI.new(meta: fc_metadata_protocol_meta)
    api.get_api
  end

  def self.fc_metadata_protocol_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_metadata_protocol_meta)
    dcat.get_dcat
  end
end
