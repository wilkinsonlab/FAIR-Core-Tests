require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.core_data_kr_language_strong_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Data Knowlege Representation Language (Strict Test)',
      testid: 'core_data_kr_language_strong',
      description: "Test if the data uses a formal language broadly applicable for knowledge representation.  This particular test takes a broad view of what defines a 'knowledge representation language'; in this evaluation, a knowledge representation language is interpreted as one in which terms are semantically-grounded in ontologies.  Any form of ontologically-grounded linked data will pass this test. ",
      metric: 'https://w3id.org/fair-metrics/general/FM_I1_M_FormLang',
      indicators: 'https://doi.org/10.25504/FAIRsharing.ec5648',
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

  def self.core_data_kr_language_strong(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: core_data_kr_language_strong_meta
    )
    output.comments << "INFO: TEST VERSION '#{core_data_kr_language_strong_meta[:testversion]}'\n"

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
      output.comments << "INFO: Now resolving #{identifier} to test its properties.\n"
      testIdentifier(guid: identifier, output: output) # this will add more comments and a score to output
    else
      output.score = 'indeterminate'
      output.comments <<  "INFO: Tested the following #{FAIRChampion::Utils::DATA_PREDICATES}(or their plain JSON hash-key equivalents)\n"
      output.comments <<  'INDETERMINATE: Was unable to locate the data identifier in the metadata using any (common) property/predicate reserved for this purpose.'
    end
    output.createEvaluationResponse
  end

  def self.testIdentifier(guid:, output:)
    type, url = FAIRChampion::Harvester.convertToURL(guid)
    if url.nil?
      output.comments << "INDETERMINATE: The GUID identifier of the data #{guid} did not match any known identification system (tested inchi, doi, handle, uri) and therefore did not pass this metric.  If you think this is an error, please contact the FAIR Metrics group (http://fairmetrics.org)."
      output.score = 'indeterminate'
      return
    end

    if type == 'handle'
      output.comments << "INFO: The GUID of the data is a Handle.\n"
    elsif type == 'doi'
      output.comments << "INFO: The GUID of the data is a DOI.\n"
    elsif type == 'inchi'
      output.comments << "INFO: The GUID of the data is a InChI.\n"
    elsif type == 'uri'
      output.comments << "INFO: The GUID of the data appears to be a URI/URL.\n"
    else
      output.comments << "INFO: The GUID of the data could not be typed, therefore it cannot be tested.\n"
      output.score = 'indeterminate'
      return
    end
    headers = FAIRChampion::Harvester.head(url, FAIRChampion::Utils::AcceptHeader) # returns headers or false
    if headers
      if headers.keys.include?(:content_type)
        type = headers[:content_type]
        rdfformats = FAIRChampion::Utils::RDF_FORMATS.values.flatten
        if rdfformats.include?(type)
          output.comments << "SUCCESS: The reported content-type of the data is [#{type}] which is a known Linked Data format\n"
          output.score = 'pass'
          nil
        else
          output.comments << "FAILURE: The reported content-type of the data is [#{type}] which is not a known Linked Data format\n"
          output.score = 'fail'
          nil
        end
      else
        output.comments << "INDETERMINATE: The URL to the data is not reporting a Content-Type in its headers.  This test will now halt.\n"
        output.score = 'indeterminate'
        nil
      end
    else
      output.comments << "INDETERMINATE: The url #{url} failed to resolve via a HEAD call with headers #{FAIRChampion::Utils::AcceptHeader}, therefore we cannot continue\n"
      output.score = 'indeterminate'
      nil
    end
  end

  def self.core_data_kr_language_strong_api
    api = OpenAPI.new(meta: core_data_kr_language_strong_meta)
    api.get_api
  end

  def self.core_data_kr_language_strong_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: core_data_kr_language_strong_meta)
    dcat.get_dcat
  end
end
