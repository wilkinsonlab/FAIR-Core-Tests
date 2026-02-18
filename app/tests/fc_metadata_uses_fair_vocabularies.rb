require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_uses_fair_vocabularies_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata uses FAIR vocabularies (strong)',
      testid: 'fc_metadata_uses_fair_vocabularies',
      description: 'Maturity Indicator to test if the linked data metadata uses terms that resolve to linked (FAIR) data.',
      metric: 'https://w3id.org/fair-metrics/general/gen2-mi-i2.ttl',
      indicators: 'https://doi.org/10.25504/FAIRsharing.96d4af',
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

  def self.fc_metadata_uses_fair_vocabularies(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_metadata_uses_fair_vocabularies_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_uses_fair_vocabularies_meta[:testversion]}'\n"

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

    g = graph
    hosthash = {}
    preds = g.map do |s|
      s.predicate unless s.predicate.value =~ %r{1999/xhtml/} or s.predicate.value =~ /rdf-syntax-ns/
    end

    preds.compact!
    preds.each { |p| (hosthash[p.host] ||= []) << p }

    count = success = 0

    hosthash.keys.each do |host|
      predicate = hosthash[host].sort.first
      output.comments << "INFO:  Testing resolution of predicates from the domain #{host}\n"
      # $stderr.puts "testing host #{host}"
      count += hosthash[host].uniq.count

      case predicate.value
      when %r{purl.org/dc/} # these resolve very slowly, so just accept that they are ok!
        output.comments << "INFO:  resolution of DC predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      when %r{/vcard/} # these resolve very slowly, so just accept that they are ok!
        output.comments << "INFO:  resolution of VCARD predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      when %r{w3\.org/ns/dcat}
        output.comments << "INFO:  resolution of DCAT predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      when %r{xmlns\.com/foaf/}
        output.comments << "INFO:  resolution of FOAF predicate #{predicate.value} accepted\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
        next
      end

      output.comments << "INFO:  testing resolution of predicate #{predicate.value}\n"
      metadata2 = FAIRChampion::Harvester.resolveit(predicate.value) # this  sends the content-negotiation for linked data
      g2 = metadata2.graph
      output.comments << if g2.size > 0
                           "INFO:  predicate #{predicate.value} resolved to linked data.\n"
                         else
                           "WARN:  predicate #{predicate.value} did not resolve to linked data.\n"
                         end

      output.comments << "INFO: If linked data was found in the previous line, it will now be tested by the following SPARQL query: 'select * where {<#{predicate.value}> ?p ?o}' \n"

      query = SPARQL.parse("select * where {<#{predicate.value}> ?p ?o}")
      results = query.execute(g2)
      if results.any?
        output.comments << "INFO: Resolving #{predicate.value}returned linked data, including that URI as a triple Subject.\n"
        # $stderr.puts "adding #{hosthash[host].uniq.count} to successes"
        success += hosthash[host].uniq.count
      else
        output.comments << "WARN:  predicate #{predicate.value} was not found as the SUBJECT of a triple, indicating that it did not resolve to its definition.\n"
      end
    end

    if count > 0 and success >= count * 0.66
      output.comments << "SUCCESS: #{success} of a total of #{count} predicates discovered in the metadata resolved to Linked Data data.  This is sufficient to pass the test.\n"
      output.score = 'pass'
    elsif count == 0
      output.comments << "FAILURE: No predicates were found that resolved to Linked Data.\n"
      output.score = 'fail'
    else
      output.comments << "FAILURE: #{success} of a total of #{count} predicates discovered in the metadata resolved to Linked Data data.  The minimum to pass this test is 2/3 (with a minimum of 3 predicates in total).\n"
      output.score = 'fail'
    end
    output.createEvaluationResponse
  end

  def self.fc_metadata_uses_fair_vocabularies_api
    api = OpenAPI.new(meta: fc_metadata_uses_fair_vocabularies_meta)
    api.get_api
  end

  def self.fc_metadata_uses_fair_vocabularies_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_metadata_uses_fair_vocabularies_meta)
    dcat.get_dcat
  end
end
