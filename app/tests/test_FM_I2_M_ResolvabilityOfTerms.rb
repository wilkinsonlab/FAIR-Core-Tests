class FAIRTest
  def self.test_FM_I2_M_ResolvabilityOfTerms_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-3.0.1',
      testname: 'OSTrails Core: Resolvability of metadata terms',
      testid: 'test_FM_I2_M_ResolvabilityOfTerms',
      description: 'This test evaluates whether the property terms (predicates or keys) used within the metadata ' \
                   'record under evaluation are themselves resolvable. ' \
                   'Inspect the structure or context of the metadata (such as a JSON-LD ' \
                   '@context mapping or XML namespace declaration) to construct full ' \
                   'URIs for the property terms. For example, if a record declares a ' \
                   '@context of http://schema.org/ and uses the property term inLanguage, ' \
                   'implementations should construct the URI http://schema.org/inLanguage and ' \
                   'attempt to resolve it over HTTP(S). ' \
                   'As a minimal implementation of Principle I2, a metadata record should receive a pass ' \
                   'from this test if at least one property term URI can be constructed and resolves ' \
                   'successfully. It receives a fail result if property term URIs can be constructed from the ' \
                   'record but none of them resolve. If no URIs can be constructed from the property terms within ' \
                   'the metadata record, the result is indeterminate.',
      metric: 'https://w3id.org/fair-metrics/general/FM_I2_M_ResolvabilityOfTerms',
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

  def self.test_FM_I2_M_ResolvabilityOfTerms(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_I2_M_ResolvabilityOfTerms_meta
    )
    output.comments << "INFO: TEST VERSION '#{test_FM_I2_M_ResolvabilityOfTerms_meta[:testversion]}'\n"

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
      output.comments << "INDETERMINATE: No linked data style metadata found, so there are no property terms to test.\n"
      output.score = 'indeterminate'
      return output.createEvaluationResponse
    end

    # The RDF parser has already expanded prefixes / @context, so each predicate is a full URI.
    # A bare term with no declared namespace (e.g. "title") cannot be expanded and so never yields an http(s) URI here.
    # Structural predicates (RDF/RDFS/OWL syntax, XHTML vocab, etc.) are skipped: we are testing the
    # vocabularies the provider chose for their deposit-related metadata, not the machinery of the serialization.
    structural = %r{^https?://(www\.w3\.org/(1999/02/22-rdf-syntax-ns|2000/01/rdf-schema|2002/07/owl|1999/xhtml)|www\.w3\.org/ns/(rdfa|xhv))}i
    terms = graph.map(&:predicate).select { |p| p.respond_to?(:uri?) && p.uri? && p.to_s =~ %r{^https?://}i }
    terms = terms.map(&:to_s).uniq.reject { |t| t =~ structural }

    if terms.empty?
      output.comments << "INDETERMINATE: No property term URIs could be constructed from the metadata. " \
                         "Property terms without a declared namespace or @context cannot be resolved.\n"
      output.score = 'indeterminate'
      return output.createEvaluationResponse
    end

    output.comments << "INFO: Found #{terms.count} distinct non-structural property term URIs in the metadata.\n"
    max_attempts = 25
    output.comments << "INFO: Only the first #{max_attempts} will be tested.\n" if terms.count > max_attempts

    output.score = 'fail' # default to fail, and then change to pass if one resolves
    terms.first(max_attempts).each do |uri|
      output.comments << "INFO: Attempting to resolve property term #{uri}\n"
      headers = FAIRChampionHarvester::Core.head(uri, FAIRChampionHarvester::Utils::AcceptHeader) # headers or false
      if headers
        output.comments << "SUCCESS: The property term #{uri} resolved.  This is sufficient to pass the test.\n"
        output.score = 'pass'
        break
      else
        output.comments << "WARN: The property term #{uri} did not resolve.\n"
      end
    end

    if output.score == 'fail'
      output.comments << "FAILURE: Property term URIs were found in the metadata, but none of those tested resolved.\n"
    end
    output.createEvaluationResponse
  end

  def self.test_FM_I2_M_ResolvabilityOfTerms_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_I2_M_ResolvabilityOfTerms_meta)
    api.get_api
  end

  def self.test_FM_I2_M_ResolvabilityOfTerms_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_I2_M_ResolvabilityOfTerms_meta)
    dcat.get_dcat
  end
end
