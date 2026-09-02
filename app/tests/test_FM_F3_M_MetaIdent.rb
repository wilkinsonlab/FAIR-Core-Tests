class FAIRTest
  def self.test_FM_F3_M_MetaIdent_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-4.0.0',
      testname: 'OSTrails Core: Data Identifier in Metadata',
      testid: 'test_FM_F3_M_MetaIdent',
      description: "Test that the identifier of the data is an unambiguous element of the metadata.
      Tested options are #{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES} ",
      metric: 'https://w3id.org/fair-metrics/general/FM_F3_M_MetaIdent',

      indicators: 'https://doi.org/10.25504/FAIRsharing.820324',
      type: 'http://edamontology.org/operation_2428',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/',
      keywords: ['FAIR Assessment', 'Identifiers', 'Findability', 'FAIR Principles'],
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

  def self.test_FM_F3_M_MetaIdent(guid:)
    FtrRuby::Output.clear_comments

    output = FtrRuby::Output.new(
      testedGUID: guid,
      meta: test_FM_F3_M_MetaIdent_meta
    )
    output.comments << "INFO: TEST VERSION '#{test_FM_F3_M_MetaIdent_meta[:testversion]}'\n"

    metadata = FAIRChampionHarvester::Core.resolveit(guid) # this is where the magic happens!

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
    properties = FAIRChampionHarvester::Core.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################

    output.comments << "INFO: Searching metadata for likely identifiers to the metadata record (i.e. reference to self)\n"
    if graph.size > 0
      output.comments << "INFO: Linked Data Found.  Now searching for the metadata identifier using appropriate linked data predicates (#{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES}).\n"

      foundID = FAIRChampionHarvester::CommonQueries::GetSelfIdentifier(metadata.graph, output)

      # query pattern-match in an object position
      unless foundID.first
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record\n"
        return output.createEvaluationResponse  # release the result from all other tests
      end
      if foundID.first.empty?
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record using predicates #{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES}. \n"
        return output.createEvaluationResponse  # release the result from all other tests
      end
      unless foundID.first =~ /\w/
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record using predicates #{FAIRChampionHarvester::Utils::SELF_IDENTIFIER_PREDICATES}. \n"
        return output.createEvaluationResponse  # release the result from all other tests
      end

    else
      output.score = 'indeterminate'
      output.comments << "INDETERMINATE: linked data metadata was not found, so its identifier could not be located. \n"
      return output.createEvaluationResponse
    end

    if foundID.include?(guid)
      output.score = 'pass'
      output.comments << "SUCCESS: the starting identifier (#{guid}) was found in the structured metadata\n"
    else
      output.score = 'fail'
      output.comments << "FAILURE: While (apparent) metadata record identifiers were found (#{foundID}) none of them matched the initial GUID provided to the test (#{guid}).  Exact identifier match is required.\n"
    end

    output.createEvaluationResponse
  end

  def self.testIdentifier(guid:, output:)
    # This is verbatim from the gen2_metadata_identifier_persistence
    type = FAIRChampionHarvester::Core.typeit(guid) # this is where the magic happens!

    output.comments << "INFO: The data guid (#{guid}) is detected as a #{type}.\n"

    if !type
      output.comments << "FAILURE: The GUID identifier of the data #{guid} did not match any known identification system.\n"
      output.score = 'fail'
    elsif type == 'uri'
      output.comments << "INFO: The data GUID appears to be a URL.  Testing known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark, doi(as URL)).\n"
      if (guid =~ /(purl)\./) or (guid =~ /(oclc)\./) or (guid =~ /(fdlp)\./) or (guid =~ /(purlz)\./) or (guid =~ /(w3id)\./) or (guid =~ /(ark):/) or (guid =~ /(doi.org)/)
        output.comments << "SUCCESS: The GUID conforms with #{::Regexp.last_match(1)}, which is known to be persistent.\n"
        output.score = 'pass'
      else
        output.comments << "FAILURE: The GUID does not conform with any known permanent-URL system.\n"
        output.score = 'fail'
      end
    else
      output.comments << "SUCCESS: The GUID of the data is a #{type}, which is known to be persistent.\n"
      output.score = 'pass'
    end
  end

  def self.test_FM_F3_M_MetaIdent_api
    api = FtrRuby::OpenAPI.new(meta: test_FM_F3_M_MetaIdent_meta)
    api.get_api
  end

  def self.test_FM_F3_M_MetaIdent_about
    dcat = FtrRuby::DCAT_Record.new(meta: test_FM_F3_M_MetaIdent_meta)
    dcat.get_dcat
  end
end
