require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest

  def self.fc_data_authorization_meta
    {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.1',
    testname: "FAIR Champion: Data Authorization",
    testid: "fc_data_authorization",
    description: "Test a discovered data GUID for the ability to implement authentication and authorization in its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  It also searches the metadata for the Dublin Core 'accessRights' property, which may point to a document describing the data access process. Recognition of other identifiers will be added upon request by the community.",
    
      metric: 'https://doi.org/10.25504/FAIRsharing.VrP6sm',
      indicators: 'https://doi.org/10.25504/FAIRsharing.8e0027',
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

  def self.fc_data_authorization(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid, 
      meta: fc_data_authorization_meta
      )

    output.comments << "INFO: TEST VERSION '#{self.fc_data_authorization_meta[:testversion]}'\n"

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

    properties = FAIRChampion::Harvester.deep_dive_properties(hash)

    output.comments << "INFO: Searching metadata for likely identifiers to the data record\n"
    id_hash = id_graph = nil  # set to nil for now

    properties.each do |keyval|
      key = nil
      value = nil
      (key, value) = keyval
      key = key.to_s

      output.comments << "INFO: Searching hash-style metadata for keys indicating a pointer to data.\n"
      FAIRChampion::Utils::DATA_PREDICATES.each do |prop|
        prop =~ %r{.*[#/]([^#/]+)$}
        prop = Regexp.last_match(1)
        output.comments << "INFO: Searching for key: #{prop}.\n"
        next unless key == prop

        output.comments << "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
        warn "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
        id_hash = value.to_s
      end
    end

    if metadata.graph.size > 0 # have we found anything yet?
      output.comments << "INFO: Searching Linked Data metadata for predicates indicating a pointer to data.\n"
      id_graph = FAIRChampion::CommonQueries::GetDataIdentifier(graph: metadata.graph)
      warn "\n\nfound identifier #{id_graph} \n\n"
    end

    if id_hash.nil? and id_graph.nil?
      output.comments << "FAILURE: No data identifier was found in the metadata record.\n"
      output.score = 'fail'
      return output.createEvaluationResponse
    end


    if id_hash
      metadata2 = FAIRChampion::Harvester.typeit(id_hash)
    else 
      metadata2 = FAIRChampion::Harvester.typeit(id_graph)
    end

    if metadata2
      output.comments << "SUCCESS: The identifier #{@identifier} is recognized as a #{metadata2}, which is resolvable by an protocol that allows authorization/authentication.\n"
      output.score = 'pass'
      output.createEvaluationResponse
    else
      output.comments << "FAILURE: The identifier #{@identifier} did not match any known identification system.\n"
      output.score = 'fail'
      output.createEvaluationResponse
    end
  end

  def self.fc_data_authorization_api
    api = OpenAPI.new(meta: fc_data_authorization_meta)
    api.get_api
  end

  def self.fc_data_authorization_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_data_authorization_meta)
    dcat.get_dcat
  end
end

