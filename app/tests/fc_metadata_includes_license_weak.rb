require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_includes_license_weak_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Includes License (weak)',
      testid: 'fc_metadata_includes_license_weak',
      description: "Maturity Indicator to test if the metadata contains an explicit pointer to the license.  This 'weak' test will use a case-insensitive regular expression, and scan both key/value style metadata, as well as linked data metadata.  Tests: xhtml, dvia, dcterms, cc, data.gov.au, and Schema license predicates in linked data, and validates the value of those properties.",
      metric: 'https://doi.org/10.25504/FAIRsharing.YAdSwh',
      indicators: 'https://doi.org/10.25504/FAIRsharing.aff99f',
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

  def self.fc_metadata_includes_license_weak(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_metadata_includes_license_weak_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_includes_license_weak_meta[:testversion]}'\n"

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

        
    output.score = "fail"
    if metadata.hash.size > 1
      output.comments << "INFO:  searching hash-style metadata for a match with /license/ in any case.\n"
      properties = FAIRChampion::Utils::deep_dive_properties(hash)

      properties.each do |keyval|
        key, value = nil, nil
        (key, value) = keyval;
        key = key.to_s
        if key =~ /license/i
          output.comments << "SUCCESS: found #{key} in hashed metadata.\n"
          output.score = "pass"
          return output.createEvaluationResponse
        end
      end
    end

    g = graph
    output.score = 'fail'
    queries = %w[
      http://www.w3.org/1999/xhtml/vocab#license https://www.w3.org/1999/xhtml/vocab#license
      http://purl.org/ontology/dvia#hasLicense	https://purl.org/ontology/dvia#hasLicense
      http://purl.org/dc/terms/license	https://purl.org/dc/terms/license
      http://creativecommons.org/ns#license	https://creativecommons.org/ns#license
      http://reference.data.gov.au/def/ont/dataset#hasLicense	https://reference.data.gov.au/def/ont/dataset#hasLicense
    ]
    if g.size > 0 # have we found anything yet?
      output.comments << "INFO: Linked data found.  Testing for one of the following predicates: #{queries}.\n"
      queries.each do |predicate|
        #			$stderr.puts "\n\nPREDICATE #{predicate}\n\n"
        query = SPARQL.parse('select ?o where {?s <' + predicate + '> ?o}')
        results = query.execute(g)
        next unless results.any?

        object = results.first[:o]
        if object.resource? && !object.anonymous?
          output.score = 'pass'
          output.comments << "SUCCESS: Found the #{predicate} predicate with a Resource as its value.\n"
        else
          output.comments << "WARN: Found the #{predicate} predicate, but it does not have a Resource as its value, thus is non-compliant.\n"
        end
      end

      output.comments << "INFO:  Testing for <https://schema.org/license>.\n"
      query = SPARQL.parse('select ?o where {?s <https://schema.org/license> ?o}')
      results = query.execute(g)
      if results.any?
        object = results.first[:o]
        if object.resource? && !object.anonymous?
          output.score = 'pass'
          output.comments << "SUCCESS: Found the Schema license predicate with a Resource as its value.\n"
        else
          output.comments << "WARN: Found the Schema license predicate, but it does not have a Resource as its value.  While this is compliant with Schema, it is not best-practice.  Please update your metadata to point to a URL containing the license.\n"
        end
      end

      output.comments << "INFO:  Testing for <http://schema.org/license>.\n"
      query = SPARQL.parse('select ?o where {?s <http://schema.org/license> ?o}')
      results = query.execute(g)
      if results.any?
        object = results.first[:o]
        if object.resource? && !object.anonymous?
          output.score = 'pass'
          output.comments << "SUCCESS: Found the Schema license predicate with a Resource as its value.\n"
        else
          output.comments << "WARN: Found the Schema license predicate, but it does not have a Resource as its value.  While this is compliant with Schema, it is not best-practice.  Please update your metadata to point to a URL containing the license.\n"
        end
      end

    else
      output.comments << 'WARN: No Linked Data metadata found.  '
    end

    output.comments << 'FAILURE: No License property was found in the metadata.  ' if output.score == 'fail'

    output.createEvaluationResponse
  end



  def self.fc_metadata_includes_license_weak_api
    api = OpenAPI.new(meta: fc_metadata_includes_license_weak_meta)
    api.get_api
  end

  def self.fc_metadata_includes_license_weak_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_metadata_includes_license_weak_meta)
    dcat.get_dcat
  end
end
