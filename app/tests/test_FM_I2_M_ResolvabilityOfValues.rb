class FAIRTest
  def self.test_FM_I2_M_ResolvabilityOfValues_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.1',
      testname: 'OSTrails Core: Resolvability of metadata values',
      testid: 'test_FM_I2_M_ResolvabilityOfValues',
      description: 'This test evaluates whether the controlled values (objects or targets) ' \
                   'linked to property terms within the metadata record under evaluation are themselves resolvable. ' \
                   'Check the value fields across the metadata record for valid URIs representing controlled ' \
                   'vocabulary terms, entities, or concepts. For example, if a schema:inLanguage property ' \
                   'contains a sameAs link pointing to http://id.loc.gov/vocabulary/iso639-2/eng, ' \
                   'implementations should attempt to resolve that value URI over HTTP(S). ' \
                   'As a minimal implementation of Principle I2, a metadata record should receive a ' \
                   'pass from this test if at least one URI contained within the ' \
                   'metadata values successfully resolves. It receives a fail result if URIs are present ' \
                   'within the metadata values but none of them resolve. If no URIs are present ' \
                   'within any of the metadata values, the result is indeterminate.',
      metric: 'https://w3id.org/fair-metrics/general/FM_I2_M_ResolvabilityOfValues',
      indicators: 'https://doi.org/10.25504/FAIRsharing.96d4af',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'resolvability', 'I2', 'FAIR Principles'],
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

  def self.test_FM_I2_M_ResolvabilityOfValues(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_I2_M_ResolvabilityOfValues_meta
    )
    output.comments << "INFO: TEST VERSION '#{test_FM_I2_M_ResolvabilityOfValues_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
      return output.createEvaluationResponse
    end

    # _hash = metadata.hash
    graph = metadata.graph
    # _properties = FAIRChampionHarvester::Core.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    if graph.size > 0 # have we found anything yet?
      output.comments << "SUCCESS: linked data style metadata found\n"
    else
      output.comments << "INDETERMINATE: No linked data style metadata found, so there are no values to test.\n"
      output.score = 'indeterminate'
      return output.createEvaluationResponse
    end

    # collect every distinct http(s) URI that appears as a value (object) in the metadata
    values = graph.map(&:object).select { |o| o.respond_to?(:uri?) && o.uri? && o.to_s =~ %r{^https?://}i }
    values = values.map(&:to_s).uniq
    values.delete(guid.to_s)

    if values.empty?
      output.comments << "INDETERMINATE: No URIs were found among the metadata values.\n"
      output.score = 'indeterminate'
      return output.createEvaluationResponse
    end

    output.comments << "INFO: Found #{values.count} distinct URI values in the metadata.\n"
    max_attempts = 25
    output.comments << "INFO: Only the first #{max_attempts} will be tested.\n" if values.count > max_attempts

    output.score = 'fail' # default to fail, and then change to pass if one resolves
    values.first(max_attempts).each do |uri|
      output.comments << "INFO: Attempting to resolve #{uri}\n"
      headers = FAIRChampionHarvester::Core.head(uri, FAIRChampionHarvester::Utils::AcceptHeader) # headers or false
      if headers
        output.comments << "SUCCESS: The value #{uri} resolved.  This is sufficient to pass the test.\n"
        output.score = 'pass'
        break
      else
        output.comments << "WARN: The value #{uri} did not resolve.\n"
      end
    end

    if output.score == 'fail'
      output.comments << "FAILURE: URIs were found in the metadata values, but none of those tested resolved.\n"
    end
    output.createEvaluationResponse
  end

  def self.test_FM_I2_M_ResolvabilityOfValues_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_I2_M_ResolvabilityOfValues_meta)
    api.get_api
  end

  def self.test_FM_I2_M_ResolvabilityOfValues_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_I2_M_ResolvabilityOfValues_meta)
    dcat.get_dcat
  end
end
