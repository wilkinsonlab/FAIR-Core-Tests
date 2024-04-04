require_relative File.dirname(__FILE__) + "/../lib/harvester.rb"

class FAIRTest
  def self.fc_structured_metadata_meta
    return {
             testversion: HARVESTER_VERSION + ":" + "Tst-2.0.0",
             testname: "FAIR Champion: Structured Metadata",
             testid: "fc_structured_metadata",
             description: "Tests whether a machine is able to find structured metadata.  This could be (for example) RDFa, embedded json, json-ld, or content-negotiated structured metadata such as RDF Turtle.",
             metric: "https://purl.org/fair-metrics/Gen2_FM_F2A",
             principle: "F2",
           }
  end

  def self.fc_structured_metadata(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: self.fc_structured_metadata_meta[:testname],
      version: self.fc_structured_metadata_meta[:testversion],
      description: self.fc_structured_metadata_meta[:description],
      metric: self.fc_structured_metadata_meta[:metric],
    )

    output.comments << "INFO: TEST VERSION '#{self.fc_structured_metadata_meta[:testversion]}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == 'unknown'
      output.score = "indeterminate"
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


    if hash.any?
      output.score = "pass"
      output.comments << "SUCCESS: Found structured metadata.\n"
    elsif graph.size > 0  # have we found anything yet?
      output.score = "pass"
      output.comments << "SUCCESS: Found linked data (this may or may not have originated from the author).\n"
    else
      output.score="fail"
      output.comments << "FAILURE: unable to find any kind of structured metadata.\n"
    end

    return output.createEvaluationResponse
  end

  def self.fc_structured_metadata_api
    schemas = { "subject" => ["string", "the GUID being tested"] }

    api = OpenAPI.new(title: self.fc_structured_metadata_meta[:testname],
                      description: self.fc_structured_metadata_meta[:description],
                      tests_metric: self.fc_structured_metadata_meta[:metric],
                      version: self.fc_structured_metadata_meta[:testversion],
                      applies_to_principle: self.fc_structured_metadata_meta[:principle],
                      path: self.fc_structured_metadata_meta[:testid],
                      organization: "OSTrails Project",
                      org_url: "https://ostrails.eu/",
                      responsible_developer: "Mark D Wilkinson",
                      email: "mark.wilkinson@upm.es",
                      developer_ORCiD: "0000-0001-6960-357X",
                      protocol: ENV.fetch("TEST_PROTOCOL", nil),
                      host: ENV.fetch("TEST_HOST", nil),
                      basePath: ENV.fetch("TEST_PATH", nil),
                      response_description: 'The response is "pass", "fail" or "indeterminate"',
                      schemas: schemas)
    api.get_api
  end
end
