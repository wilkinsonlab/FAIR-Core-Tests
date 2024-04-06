require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'

class FAIRTest
  def self.fc_metadata_identifier_in_metadata_meta
    {
      testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
      testname: 'FAIR Champion: Metadata Identifier Explicitly In Metadata',
      testid: 'fc_metadata_identifier_in_metadata',
      description: "Metric to test if the metadata contains the unique identifier to the metadata itself.  This is done using a variety of 'scraping' tools, including DOI metadata resolution, the use of the 'extruct' Python tool, and others.  The test is executed by searching for the predicates 'http[s]://purl.org/dc/terms/identifier','http[s]://schema.org/identifier.",
      metric: 'https://purl.org/fair-metrics/Gen2_FM_F3',
      principle: 'F3'
    }
  end

  def self.fc_metadata_identifier_in_metadata(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_metadata_identifier_in_metadata_meta[:testid], 
      name: fc_metadata_identifier_in_metadata_meta[:testname],
      version: fc_metadata_identifier_in_metadata_meta[:testversion],
      description: fc_metadata_identifier_in_metadata_meta[:description],
      metric: fc_metadata_identifier_in_metadata_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{fc_metadata_identifier_in_metadata_meta[:testversion]}'\n"

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

    if graph.size > 0
      output.comments << "INFO: Linked Data Found.  Now searching for the metadata identifier using appropriate linked data predicates (#{FAIRChampion::Utils::SELF_IDENTIFIER_PREDICATES}).\n"

      foundID = FAIRChampion::CommonQueries::GetSelfIdentifier(metadata.graph, output)

      # query pattern-match in an object position
      unless foundID.first
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record\n"
        return output.createEvaluationResponse  # release the result from all other tests
      end
      if foundID.first.empty?
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record using predicates #{FAIRChampion::Utils::SELF_IDENTIFIER_PREDICATES}. \n"
        return output.createEvaluationResponse  # release the result from all other tests
      end
      unless foundID.first =~ /\w/
        output.score = 'fail'
        output.comments << "FAILURE: No metadata identifiers were found in the metadata record using predicates #{FAIRChampion::Utils::SELF_IDENTIFIER_PREDICATES}. \n"
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

  def self.fc_metadata_identifier_in_metadata_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(title: fc_metadata_identifier_in_metadata_meta[:testname],
                      description: fc_metadata_identifier_in_metadata_meta[:description],
                      tests_metric: fc_metadata_identifier_in_metadata_meta[:metric],
                      version: fc_metadata_identifier_in_metadata_meta[:testversion],
                      applies_to_principle: fc_metadata_identifier_in_metadata_meta[:principle],
                      path: fc_metadata_identifier_in_metadata_meta[:testid],
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
