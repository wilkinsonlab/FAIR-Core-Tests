class FAIRTest
  def self.test_FM_I3_M_RRO_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-1.0.0',
      testname: 'OSTrails Core: Metadata Contains Qualified Links to Related Research Objects',
      testid: 'test_FM_I3_M_RRO',
      description: 'Maturity Indicator to test if the metadata links to other related research objects.
      Note that this test only examines metadata that is represented as Linked Data.
      The test passes if the object of any triple (non-structural triples only) is a URI.
      Unlike test_FM_I3_M_QualRef, the referenced URI is NOT required to be on a different host than the
      metadata itself, so cross-references between related records in the same database (domain) are acceptable.
      This is a very weak test, but it is designed to encourage data stewards to link their metadata to
      other research objects. ',
      metric: 'https://w3id.org/fair-metrics/general/FM_I3_M_RRO',
      indicators: 'https://doi.org/10.25504/FAIRsharing.ae22b8',
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

  def self.test_FM_I3_M_RRO(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_I3_M_RRO_meta
    )

    output.comments << "INFO: TEST VERSION '#{test_FM_I3_M_RRO_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    graph = metadata.graph
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    g = graph

    if g.size > 0 # have we found anything yet?
      output.comments << "INFO: Linked data was found.\n"
    else
      output.comments << "FAILURE: No linked data was found.  Test is exiting.\n"
      output.score = 'fail'
      return output.createEvaluationResponse
    end

    success = 0
    count = 0
    g.each do |stm|
      predicate = stm.predicate
      next if predicate.to_s =~ %r{1999/xhtml} # ignore XHTML structural triples like buttons

      object = stm.object
      next unless object.resource? && !object.anonymous?

      output.comments << "INFO: Testing #{object.value}.\n"
      success += 1 # NOTE: unlike QualRef, links to the same host/domain as the metadata are acceptable
      count += 1
    end

    if success >= 1 # this is a very weak test!
      output.comments << "SUCCESS: #{success} of the #{count} triples discovered in the linked metadata pointed to other research objects.  "
      output.score = 'pass'
    else
      output.comments << "FAILURE: #{success} of the #{count} triples discovered in the linked metadata pointed to other research objects.  The minimum to pass this test is 1.  "
      output.score = 'fail'
    end

    output.createEvaluationResponse
  end

  def self.test_FM_I3_M_RRO_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_I3_M_RRO_meta)
    api.get_api
  end

  def self.test_FM_I3_M_RRO_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_I3_M_RRO_meta)
    dcat.get_dcat
  end
end
