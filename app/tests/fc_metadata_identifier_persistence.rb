require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_identifier_persistence_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Identifier Persistence',
      testid: 'fc_metadata_identifier_persistence',
      description: "Metric to test if the unique identifier of the metadata resource is likely to be persistent. Known schema are registered in FAIRSharing (https://fairsharing.org/standards/?q=&selected_facets=type_exact:identifier%20schema). For URLs that don't follow a schema in FAIRSharing we test known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark).",
      metric: 'https://w3id.org/fair-metrics/general/Gen2-MI-F1'.downcase,
      indicators: 'https://doi.org/10.25504/FAIRsharing.e226cb',
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

  def self.fc_metadata_identifier_persistence(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      meta: fc_metadata_identifier_persistence_meta
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_identifier_persistence_meta[:testversion]}'\n"

    type = FAIRChampion::Harvester.typeit(guid)

    # metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    # metadata.comments.each do |c|
    #   output.comments << c
    # end

    # if metadata.guidtype == 'unknown'
    #   output.score = "indeterminate"
    #   output.comments << "INDETERMINATE: The identifier #{guid} did not match any known identification system.\n"
    #   return output.createEvaluationResponse
    # end

    # hash = metadata.hash
    # graph = metadata.graph
    # properties = FAIRChampion::Harvester.deep_dive_properties(hash)
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    #############################################################################################################
    if !type
      output.comments << "FAILURE: The GUID identifier of the metadata #{guid} did not match any known identification system.\n"
      output.score = 'fail'
    elsif type == 'uri'
      output.comments << "INFO: The metadata GUID appears to be a URL.  Testing known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark, doi(as URL)).\n"
      if (guid =~ /(purl)\./) or (guid =~ /(oclc)\./) or (guid =~ /(fdlp)\./) or (guid =~ /(purlz)\./) or (guid =~ /(w3id)\./) or (guid =~ /(ark):/) or (guid =~ /(doi.org)/)
        output.comments << "SUCCESS: The metadata GUID conforms with #{::Regexp.last_match(1)}, which is known to be persistent.\n"
        output.score = 'pass'
      else
        output.comments << "FAILURE: The metadata GUID does not conform with any known permanent-URL system.\n"
        output.score = 'fail'
      end
    else
      output.comments << "SUCCESS: The GUID of the metadata is a #{type}, which is known to be persistent.\n"
      output.score = 'pass'
    end
    output.createEvaluationResponse
  end

  def self.fc_metadata_identifier_persistence_api
    api = OpenAPI.new(meta: fc_metadata_identifier_persistence_meta)
    api.get_api
  end

  def self.fc_metadata_identifier_persistence_about
    dcat = ChampionDCAT::DCAT_Record.new(meta: fc_metadata_identifier_persistence_meta)
    dcat.get_dcat
  end
end
