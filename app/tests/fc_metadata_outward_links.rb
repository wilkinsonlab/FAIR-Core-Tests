require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_outward_links_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Contains Outward Links',
      testid: 'fc_metadata_outward_links',
      description: 'Maturity Indicator to test if the metadata links outward to third-party resources.  It only tests metadata that can be represented as Linked Data.',
      metric: 'https://purl.org/fair-metrics/Gen2_FM_I3A',
      principle: 'I3'
    }
  end

  def self.fc_metadata_outward_links(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_metadata_outward_links_meta[:testid], 
      name: fc_metadata_outward_links_meta[:testname],
      version: fc_metadata_outward_links_meta[:testversion],
      description: fc_metadata_outward_links_meta[:description],
      metric: fc_metadata_outward_links_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_outward_links_meta[:testversion]}'\n"

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

    if g.size > 0 # have we found anything yet?
      output.comments << "INFO: Linked data was found.\n"
    else
      output.comments << "FAILURE: No linked data was found.  Test is exiting.\n"
      output.score = 'fail'
      return output.createEvaluationResponse
    end

    success = 0 # we will accept 5/10 failures
    count = 0
    metadata.finalURI.each do |uri|
      next unless uri.is_a?(URI::HTTP)

      output.comments << "INFO: Now testing for any triples whose Object is an outward link (i.e. not #{uri.host})\n"
    end

    hosts = []
    # fill the list of domains that this resource is found i
    metadata.finalURI.each do |uri|
      next unless uri =~ /http/

      this = URI(uri)
      hosts << this.host
    end
    g.each do |stm|
      predicate = stm.predicate
      next if predicate.to_s =~ %r{1999/xhtml} # ignore XHTML structural triples like buttons

      object = stm.object
      next unless object.resource? && !object.anonymous?

      thisuri = URI(object.value)
      output.comments << "INFO: Testing #{thisuri}.\n"
      success += 1 unless hosts.include?(thisuri.host) # NOTE: that we're checking for outward links
      count += 1
    end

    if success >= 1 # this is a very weak test!
      output.comments << "SUCCESS: #{success} of the #{count} triples discovered in the linked metadata pointed to resources hosted elsewhere.  "
      output.score = 'pass'
    else
      output.comments << "FAILURE: #{success} of the #{count} triples discovered in the linked metadata pointed to resources hosted elsewhere.  The minimum to pass this test is 1.  "
      output.score = 'fail'
    end

    output.createEvaluationResponse
  end

  def self.fc_metadata_outward_links_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(title: fc_metadata_outward_links_meta[:testname],
                      description: fc_metadata_outward_links_meta[:description],
                      tests_metric: fc_metadata_outward_links_meta[:metric],
                      version: fc_metadata_outward_links_meta[:testversion],
                      applies_to_principle: fc_metadata_outward_links_meta[:principle],
                      path: fc_metadata_outward_links_meta[:testid],
                      organization: 'OSTrails Project',
                      org_url: 'https://ostrails.eu/',
                      responsible_developer: 'Mark D Wilkinson',
                      email: 'mark.wilkinson@upm.es',
                      developer_ORCiD: '0000-0001-6960-357X',
                      protocol: ENV.fetch('TEST_PROTOCOL', nil),
                      host: ENV.fetch('TEST_HOST', nil),
                      basePath: ENV.fetch('TEST_PATH', nil),
                      response_description: 'The response is "pass", "fail" or "indeterminate"',
                      schemas: schemas)

    api.get_api
  end
end
