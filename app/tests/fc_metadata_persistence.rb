require_relative File.dirname(__FILE__) + '/../lib/harvester.rb'


class FAIRTest
  def self.fc_metadata_persistence_meta
    return {
    testversion: HARVESTER_VERSION + ':' + 'Tst-2.0.0',
    testname:"FAIR Champion: Metadata Persistence",
    testid: "fc_metadata_persistence",
    description: "Metric to test if the metadata contains a persistence policy, explicitly identified by a persistencePolicy key (in hashed data) or a http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy predicate in Linked Data.",
    metric: 'https://purl.org/fair-metrics/Gen2_FM_FA2',
    principle: "A2"
    }
  end

  def self.fc_metadata_persistence(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: self.fc_metadata_persistence_meta[:testname], 
      version: self.fc_metadata_persistence_meta[:testversion],
      description: self.fc_metadata_persistence_meta[:description], 
      metric:self.fc_metadata_persistence_meta[:metric]
    )

    output.comments << "INFO: TEST VERSION '#{TESTVERSION}'\n"

    metadata = FAIRChampion::Harvester.resolveit(guid) # this is where the magic happens!

    hash = metadata.hash
    graph = metadata.graph
    properties = FAIRChampion::Harvester.deep_dive_properties(hash)
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################

    g = graph  # shorter :-)
      
    if g.size > 0  # have we found anything yet?
      output.comments << "INFO: Found linked data.  Testing for the 'http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy' predicate.\n"
      query = SPARQL.parse("select ?o where {?s <http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy> ?o}")
      results = query.execute(g)
      if results.any?
        output.comments << "INFO: Found persistence policy predicate with #{results.first[:o]} as its value.  This should be a resolveable URL; Now testing resolution.\n"
        policyURI = results.first[:o].value
        unless policyURI =~ /:\/\/\w+\.\w+/  # the structure of a URI
          output.comments << "FAILURE: http://www.w3.org/2000/10/swap/pim/doc#persistencePolicy states that the range of the property must be a resource.  The discovered value (#{polucyURI}) is not a URL.\n"
          output.score = "fail"
          return output.createEvaluationResponse
        end
        
        head, body = Utils::fetch(policyURI, {"Accept" => "*/*"})  # returns HTTP object, or false
        if head
          output.comments << "SUCCESS: Persistence policy URL resolved.\n"
          output.score = "pass"
          return output.createEvaluationResponse
        else
          output.comments << "FAILURE: Persistence policy did not resolve.\n"
          output.score = "fail"
          return output.createEvaluationResponse
        end
      else
        output.comments << "WARN: Did not find the #persistencePolicy predicate in the linked data.\n"
      end
        
    else 
      output.comments << "WARN: Could not find any linked data to test for persistence policy references.\n"
    end

    if output.score == "fail"
      output.comments << "FAILURE: detected that there might be a persistence policy, but it failed expectations.\n"
    else
      output.score == "indeterminate"
      output.comments << "INDETERMINATE: was unable to find a persistence policy using any approach.\n"
    end


    return output.createEvaluationResponse
  end


  
  def self.fc_metadata_persistence_api
    schemas = { 'subject' => ['string', 'the GUID being tested'] }

    api = OpenAPI.new(      title: self.fc_metadata_persistence_meta[:testname],
                            description: self.fc_metadata_persistence_meta[:description],
                            tests_metric: self.fc_metadata_persistence_meta[:metric],
                            version: self.fc_metadata_persistence_meta[:testversion],
                            applies_to_principle: self.fc_metadata_persistence_meta[:principle],
                            organization: 'OSTrails Project',
                            org_url: 'https://ostrails.eu/',
                            responsible_developer: 'Mark D Wilkinson',
                            email: 'mark.wilkinson@upm.es',
                            developer_ORCiD: '0000-0001-6960-357X',
                            protocol: ENV.fetch('TEST_PROTOCOL', nil),
                            host: ENV.fetch('TEST_HOST', nil),
                            basePath: ENV.fetch('TEST_PATH', nil),
                            path: self.fc_metadata_persistence_meta[:testid],
                            response_description: 'The response is "pass", "fail" or "indeterminate"',
                            schemas: schemas,
                          )

    api.get_api
  end
end