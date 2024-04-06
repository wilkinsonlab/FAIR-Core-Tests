require_relative File.dirname(__FILE__) + "/../lib/harvester.rb"

class FAIRTest
  def self.fc_metadata_kr_language_weak_meta
    return {
             testversion: HARVESTER_VERSION + ":" + "Tst-2.0.0",
             testname: "FAIR Champion: Metadata Knowledge Representation Language (weak)",
             testid: "fc_metadata_kr_language_weak",
             description: "Maturity Indicator to test if the metadata uses a formal language broadly applicable for knowledge representation.  This particular test takes a broad view of what defines a 'knowledge representation language'; in this evaluation, anything that can be represented as structured data will be accepted.",
             metric: "https://purl.org/fair-metrics/Gen2_FM_I1A",
             principle: "I1",
           }
  end

  def self.fc_metadata_kr_language_weak(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      testid: fc_metadata_kr_language_weak_meta[:testid], 
      name: self.fc_metadata_kr_language_weak_meta[:testname],
      version: self.fc_metadata_kr_language_weak_meta[:testversion],
      description: self.fc_metadata_kr_language_weak_meta[:description],
      metric: self.fc_metadata_kr_language_weak_meta[:metric],
    )

    output.comments << "INFO: TEST VERSION '#{self.fc_metadata_kr_language_weak_meta[:testversion]}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    metadata.comments.each do |c|
      output.comments << c
    end

    if metadata.guidtype == "unknown"
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
      output.comments << "SUCCESS: Found structured data.\n"
    elsif graph.size > 0 # have we found anything yet?
      output.score = "pass"
      output.comments << "SUCCESS: Found linked data (this may or may not have originated from the author).\n"
    else
      output.score = "fail"
      output.comments << "FAILURE: unable to find any kind of structured metadata.\n"
    end

    return output.createEvaluationResponse
  end

  def self.fc_metadata_kr_language_weak_api
    schemas = { "subject" => ["string", "the GUID being tested"] }

    api = OpenAPI.new(title: self.fc_metadata_kr_language_weak_meta[:testname],
                      description: self.fc_metadata_kr_language_weak_meta[:description],
                      tests_metric: self.fc_metadata_kr_language_weak_meta[:metric],
                      version: self.fc_metadata_kr_language_weak_meta[:testversion],
                      applies_to_principle: self.fc_metadata_kr_language_weak_meta[:principle],
                      path: self.fc_metadata_kr_language_weak_meta[:testid],
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
