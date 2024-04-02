require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_identifier_persistence_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Identifier Persistence',
      testid: 'fc_metadata_identifier_persistence',
      description: "Metric to test if the unique identifier of the metadata resource is likely to be persistent. Known schema are registered in FAIRSharing (https://fairsharing.org/standards/?q=&selected_facets=type_exact:identifier%20schema). For URLs that don't follow a schema in FAIRSharing we test known URL persistence schemas (purl, oclc, fdlp, purlz, w3id, ark).",
      metric: 'https://purl.org/fair-metrics/Gen2_FM_F1B',
      principle: 'F1'
    }
  end

  def self.fc_metadata_identifier_persistence(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: fc_metadata_identifier_persistence_meta[:testname],
      version: fc_metadata_identifier_persistence_meta[:testversion],
      description: fc_metadata_identifier_persistence_meta[:description],
      metric: fc_metadata_identifier_persistence_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_identifier_persistence_meta[:testversion]}'\n"

    type = FAIRChampion::Utils.typeit(guid)

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
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(title: fc_metadata_identifier_persistence_meta[:testname],
                      description: fc_metadata_identifier_persistence_meta[:description],
                      tests_metric: fc_metadata_identifier_persistence_meta[:metric],
                      version: fc_metadata_identifier_persistence_meta[:testversion],
                      applies_to_principle: fc_metadata_identifier_persistence_meta[:principle],
                      path: fc_metadata_identifier_persistence_meta[:testid],
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
