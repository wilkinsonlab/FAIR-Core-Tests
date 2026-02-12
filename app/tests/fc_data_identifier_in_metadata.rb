require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_data_identifier_in_metadata_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.1',
      testname: 'FAIR Champion: Data Identifier in Metadata',
      testid: 'fc_data_identifier_in_metadata',
      description: 'Test that the identifier of the data is an unambiguous element of the metadata. Tested options are schema:distribution, http://www.w3.org/ns/ldp#contains, iao:IAO_0000136, IAO:0000136,ldp:contains,foaf:primaryTopic,schema:distribution,schema:contentUrl,schema,mainEntity,schema:codeRepository,schema:distribution,schema:contentUrl, dcat:distribution, dcat:dataset,dcat:downloadURL,dcat:accessURL,sio:SIO_000332, sio:is-about, obo:IAO_0000136',
      metric: 'https://w3id.org/fair-metrics/general/Gen2-MI-F3'.downcase,
      indicators: 'https://doi.org/10.25504/FAIRsharing.820324',
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

  def self.fc_data_identifier_in_metadata(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_data_identifier_in_metadata_meta
    )
    output.comments << "INFO: TEST VERSION '#{fc_data_identifier_in_metadata_meta[:testversion]}'\n"

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
      _ = nil
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
      output.comments << "INFO: Now resolving #{identifier} to test its properties.\n"
      testIdentifier(guid: identifier, output: output) # this will add more comments and a score to @swagger
    else
      output.score = 'fail'
      output.comments <<  "INFO: Tested the following #{FAIRChampion::Utils::DATA_PREDICATES}(or their plain JSON hash-key equivalents)\n"
      output.comments <<  'FAILURE: Was unable to locate the data identifier in the metadata using any (common) property/predicate reserved for this purpose.'
    end
    output.createEvaluationResponse
  end

  def self.testIdentifier(guid:, output:)
    # This is verbatim from the gen2_metadata_identifier_persistence
    type = FAIRChampion::Harvester.typeit(guid) # this is where the magic happens!

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

  def self.fc_data_identifier_in_metadata_api
    api = OpenAPI.new(meta: fc_data_identifier_in_metadata_meta)
    api.get_api
  end

  def self.fc_data_identifier_in_metadata_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_data_identifier_in_metadata_meta)
    dcat.get_dcat
  end
end
