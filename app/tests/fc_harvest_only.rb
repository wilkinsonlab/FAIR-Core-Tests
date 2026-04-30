class FAIRTest
  def self.fc_harvest_only_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'OSTrails Core: Expose Harvester Raw Output',
      testid: 'fc_harvest_only',
      description: 'This test is designed to expose the raw output of the FAIR Champion Harvester.  It is not designed to be a FAIR test, but rather a debugging tool for developers of the harvester and the FAIR tests that depend on it.  The test will return the raw output of the harvester, including any comments generated during the harvesting process.  The test will not attempt to interpret the output or assign a score, but will simply return the raw output for inspection by developers.  ',
      metric: 'https://doi.org/10.25504/FAIRsharing.VRo9Dl',
      indicators: 'https://doi.org/10.25504/FAIRsharing.e226cb',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'FAIR Principles'],
      themes: ['http://edamontology.org/topic_4012'],
      organization: 'OSTrails Project',
      org_url: 'https://ostrails.eu/',
      responsible_developer: 'Mark D Wilkinson',
      email: 'mark.wilkinson@upm.es',
      response_description: 'The response is the raw output from harvesting',
      schemas: { 'resource_identifier' => ['string', 'the GUID being tested'] },
      organizations: [{ 'name' => 'OSTrails Project', 'url' => 'https://ostrails.eu/' }],
      individuals: [{ 'name' => 'Mark D Wilkinson', 'email' => 'mark.wilkinson@upm.es' }],
      creator: 'https://orcid.org/0000-0001-6960-357X',
      protocol: ENV.fetch('TEST_PROTOCOL', 'https'),
      host: ENV.fetch('TEST_HOST', 'localhost'),
      basePath: ENV.fetch('TEST_PATH', '/tests')
    }
  end

  def self.fc_harvest_only(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: fc_harvest_only_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_harvest_only_meta[:testversion]}'\n"

    # type = FAIRChampionHarvester::Core.typeit(guid)

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    hash = metadata.hash
    graph = metadata.graph

    graph_nodes = begin
      JSON.parse(graph.dump(:jsonld))
    rescue StandardError
      []
    end
    graph_nodes = Array(graph_nodes['@graph']) unless graph_nodes.is_a?(Array)

    JSON.pretty_generate(
      '@context' => { 'local' => 'urn:local:harvester:' },
      '@graph' => [
        { '@id' => 'urn:local:harvester:graph',
          'local:triples' => graph_nodes },
        { '@id' => 'urn:local:harvester:hash',
          'local:hash' => hash.map { |k, v| { 'local:key' => k.to_s, 'local:value' => v.to_s } } },
        { '@id' => 'urn:local:harvester:comments',
          'local:comments' => output.comments }
      ]
    )
  end

  def self.fc_harvest_only_api
    api = FtrRuby::OpenAPI.new(meta: fc_harvest_only_meta)
    api.get_api
  end

  def self.fc_harvest_only_about
    dcat = FtrRuby::DCAT_Record.new(meta: fc_harvest_only_meta)
    dcat.get_dcat
  end
end
