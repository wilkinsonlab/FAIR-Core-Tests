require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_data_protocol_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Data Protocol',
      testid: 'fc_data_protocol',
      description: 'Data may be retrieved by an open and free protocol.  Tests data GUID for its resolution protocol.  Currently passes InChI Keys, DOIs, Handles, and URLs.  Recognition of other identifiers will be added upon request by the community.',
      metric: 'https://w3id.org/fair-metrics/general/champ-mi-a1.1.ttl',
      indicators: 'https://doi.org/10.25504/FAIRsharing.7612c1',
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

  def self.fc_data_protocol(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_data_protocol_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_data_protocol_meta[:testversion]}'\n"

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

    output.comments << "INFO: Searching metadata for likely identifiers to the data record\n"
    identifier = nil

    properties.each do |keyval|
      key = nil
      value = nil
      (key, value) = keyval
      key = key.to_s

      output.comments << "INFO: Searching hash-style metadata for keys indicating a pointer to data.\n"
      FAIRChampion::Utils::DATA_PREDICATES.each do |prop|
        prop =~ %r{.*[#/]([^#/]+)$}
        prop = ::Regexp.last_match(1)
        output.comments << "INFO: Searching for key: #{prop}.\n"
        if key == prop
          output.comments << "INFO: found '#{prop}' in metadata.  Setting data GUID to #{value} for next test.\n"
          identifier = value.to_s
        end
      end
    end

    if graph.size > 0 # have we found anything yet?
      output.comments << "INFO: Searching Linked Data metadata for predicates indicating a pointer to data.\n"
      identifier = FAIRChampion::CommonQueries::GetDataIdentifier(graph: graph)
    end

    if identifier =~ /\w+/
      metadata2 = FAIRChampion::Harvester.typeit(identifier)
      if metadata2
        output.comments << "SUCCESS: The identifier #{@identifier} is recognized as a #{metadata2}, which is resolvable by an open and free protocol.\n"
        output.score = 'pass'
      else
        output.comments << "FAILURE: The identifier #{@identifier} did not match any known identification system.\n"
        output.score = 'fail'
      end
    else
      output.score = 'indeterminate'
      output.comments <<  "INFO: Tested the following #{FAIRChampion::Utils::DATA_PREDICATES}(or their plain JSON hash-key equivalents)\n"
      output.comments <<  'INDETERMINATE: Was unable to locate the data identifier in the metadata using any (common) property/predicate reserved for this purpose.'
    end
    output.createEvaluationResponse
  end

  def self.fc_data_protocol_api
    api = OpenAPI.new(meta: fc_data_protocol_meta)
    api.get_api
  end

  def self.fc_data_protocol_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_data_protocol_meta)
    dcat.get_dcat
  end
end
