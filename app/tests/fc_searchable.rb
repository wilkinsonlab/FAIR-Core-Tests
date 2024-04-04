require_relative File.dirname(__FILE__) + "/../lib/harvester.rb"

class FAIRTest
  def self.fc_searchable_meta
    return {
             testversion: HARVESTER_VERSION + ":" + "Tst-2.0.0",
             testname: "FAIR Champion: Searchable in major search engine",
             testid: "fc_searchable",
             description: "Tests whether a machine is able to discover the resource by search, using Microsoft Bing.",
             metric: "https://purl.org/fair-metrics/Gen2_FM_F4",
             principle: "F4",
           }
  end

  def self.fc_searchable(guid:)
    FAIRChampion::Output.clear_comments

    output = FAIRChampion::Output.new(
      testedGUID: guid,
      name: self.fc_searchable_meta[:testname],
      version: self.fc_searchable_meta[:testversion],
      description: self.fc_searchable_meta[:description],
      metric: self.fc_searchable_meta[:metric],
    )

    output.comments << "INFO: TEST VERSION '#{self.fc_searchable_meta[:testversion]}'\n"

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
    ###################  TITLE
    output.comment << "INFO: testing any hash-style metadata for a key matching 'title' in any case.\n"
    flatlist = hash.flatten(40) # hopefully no hash is more than 40 deep!
    title = ""
    for x in 1..flatlist.length
      term = flatlist[x - 1]
      next if !term.is_a? String
      #warn term
      if term.match(/title$/i) # in a flattened hash, find something matching 'title' at the end of the term
        title = flatlist[x]  # the next thing should be the title
        break
      end
    end
    unless title =~ /\w+/
      output.comment << "WARN: could not find a structured reference to the title in the hash-style metadata.\n"
    end

    if title =~ /\w+/
      output.comment << "INFO: found title #{title}.  Searching Bing\n"
      warn "Calling Bing with title #{title}\n\n"

      searchresults = callBing(title)
      h = JSON.parse(searchresults)
      if h["webPages"]
        output.comment << "INFO: found matches in Bing.  Checking for results that match any of #{finalURI.map { |b| b.to_s }}.\n"
        finalURI = finalURI.map { |b| b.downcase }  # make case insensitive search
        h["webPages"]["value"].each do |p|
          if finalURI.include?(p["url"].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
            output.comment << "SUCCESS: found a search record referencing #{p["url"]} based on an exact-match title search against Bing.\n  "
            output.score = "pass"
          end
        end
        unless output.score == "pass"
          output.comment << "INFO: No results from Bing included any of #{finalURI.map { |b| b.to_s }}.\n"
        end
      else
        output.comment << "WARN:  Bing search for #{title} found no results.\n"
      end
    end

    #############  Keywords
    flatlist = hash.flatten(40) # hopefully no hash is more than 40 deep!
    keywords = ""
    for x in 1..flatlist.length
      term = flatlist[x - 1]
      #warn term
      next if !term.is_a? String
      if term.match(/keywords?$/i) # in a flattened hash, find something matching 'keywords?' at the end of the term
        keywords = flatlist[x]  # the next thing should be the keywords
        break
      end
    end
    #keywords = keywords.gsub!("\,", "")
    unless keywords =~ /\w+/
      output.comment << "WARN: could not find any human-readeable keywords in hash-style metadata.\n"
    end

    if keywords =~ /\w+/
      output.comment << "INFO: found keywords #{keywords}.  Now searching Bing.\n"
      warn "Calling Bing with hash keywords #{keywords}\n\n"

      searchresults = callBing(keywords)
      h = JSON.parse(searchresults)
      if h["webPages"]
        output.comment << "INFO: found matches in Bing.  Checking for results that match any of #{finalURI.map { |b| b.to_s }}\n"
        finalURI = finalURI.map { |b| b.downcase }  # make case insensitive search
        h["webPages"]["value"].each do |p|
          if finalURI.include?(p["url"].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
            output.comment << "SUCCESS: found a search hit matching #{p["url"]} using metadata keywords in search on Bing.\n  "
            output.score = "pass"
          end
        end
        unless output.score == "pass"
          output.comment << "INFO: No keyword search results from Bing included any of #{finalURI.map { |b| b.to_s }}.\n"
        end
      else
        output.comment << "INFO: Bing returned no search results for keywords #{keywords}.\n"
      end
    end

    #####################  now with the graph data

    g = metadata.graph

    if g.size > 0 # have we found anything
      output.comment << "INFO: Testing Linked Data-formatted metadata for any predicate that contains 'title' in any case.\n "
      query = SPARQL.parse("select distinct ?o where {?s ?p ?o  FILTER(CONTAINS(lcase(str(?p)), 'title'))}") # find predicate containing "title", take object
      results = query.execute(g)
      if results.any?
        output.comment << "INFO: found title predicate.\n "
        seen = Hash.new(false)  # appaerntly, distinct isn't working in the sparql...??
        results.each do |res|
          next if seen[res[:o].to_s]
          seen[res[:o].to_s] = true

          title = res[:o].to_s  # get the title
          output.comment << "INFO: found possible Title:  #{title}.\n "
          #warn "looking for #{title}"
          output.comment << "INFO: Calling Bing search using #{title}.\n "
          warn "Calling Bing with graph title #{title}\n\n"

          searchresults = callBing(title)  # search bing
          #warn JSON::pretty_generate(JSON(searchresults))
          h = JSON.parse(searchresults)  # parse json
          if h["webPages"] # are there results
            output.comment << "INFO: Bing found results for#{title}.  Checking for results that match #{finalURI.map { |b| b.to_s }}.\n"
            finalURI = finalURI.map { |b| b.downcase }  # make case insensitive search
            h["webPages"]["value"].each do |p| # for each matching pge do
              if finalURI.include?(p["url"].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
                output.comment << "SUCCESS: found a search record referencing #{p["url"]} based on an exact-match title search against Bing.\n  "
                output.score = "pass"
              end
            end
            unless output.score == "pass"
              output.comment << "INFO: No results from Bing included any of #{finalURI.map { |b| b.to_s }}.\n"
            end
          else
            output.comment << "INFO: No search results from Bing using the title of the record\n  "
          end
        end
      end
      query = SPARQL.parse("select distinct ?o where {?s ?p ?o  FILTER(CONTAINS(lcase(str(?p)), 'name'))}") # find predicate containing "name", take object
      results = query.execute(g)
      if results.any?
        output.comment << "INFO: found a 'name' predicate; presuming this is a pointer to a title.\n "
        seen = Hash.new(false)  # appaerntly, distinct isn't working in the sparql...??
        results.each do |res|
          next if seen[res[:o].to_s]
          seen[res[:o].to_s] = true
          title = res[:o].to_s  # get the title
          output.comment << "INFO: found possible Title:  #{title}.\n "
          #warn "looking for #{title}"
          output.comment << "INFO: Calling Bing search using #{title}.\n "
          warn "Calling Bing with graph name #{title}\n\n"

          searchresults = callBing(title)  # search bing
          #warn JSON::pretty_generate(JSON(searchresults))
          h = JSON.parse(searchresults)  # parse json
          if h["webPages"] # are there results
            output.comment << "INFO: Bing found results for#{title}.  Checking for results that match #{finalURI.map { |b| b.to_s }}.\n"
            finalURI = finalURI.map { |b| b.downcase }  # make case insensitive search
            h["webPages"]["value"].each do |p| # for each matching pge do
              if finalURI.include?(p["url"].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
                output.comment << "SUCCESS: found a search record referencing #{p["url"]} based on an exact-match title search against Bing.\n  "
                output.score = "pass"
              end
            end
            unless output.score == "pass"
              output.comment << "INFO: No results from Bing included any of #{finalURI.map { |b| b.to_s }}.\n"
            end
          else
            output.comment << "INFO: No search results from Bing\n  "
          end
        end
      end
    end

    #######  keywords in graph

    g = metadata.graph

    if g.size > 0 # have we found anything
      output.comment << "INFO: Testing Linked Data-formatted metadata for any predicate that contains 'keyword' in any case.\n "
      query = SPARQL.parse("select distinct ?o where {?s ?p ?o  FILTER(CONTAINS(lcase(str(?p)), 'keyword'))}") # find predicate containing "title", take object
      results = query.execute(g)
      if results.any?
        seen = Hash.new(false)  # appaerntly, distinct isn't working in the sparql...??
        results.each do |res|
          next if seen[res[:o].to_s]
          seen[res[:o].to_s] = true
          keywords = res[:o].to_s  # get the keywords
          output.comment << "INFO: found keywords.\n "
          output.comment << "INFO: found keywords #{keywords}.\n "
          output.comment << "INFO: Calling Bing search using #{keywords}.\n "
          warn "Calling Bing with graph keywords #{keywords}\n\n"

          searchresults = callBing(keywords)  # search bing
          #warn "keywords #{keywords}"
          #warn "results: #{searchresults}"
          h = Hash.new
          begin
            h = JSON.parse(searchresults)  # parse json
          rescue
            warn "whatever came back from Bing was not parsable JSON"
            output.comment << "INFO: Bing returned a non-JSON response, indicating that the request failed for some reason\n"
          end

          if h["webPages"] # are there results
            output.comment << "INFO: Bing found matches using #{keywords}. Testing matches for a reference to #{finalURI.map { |b| b.to_s }}\n"
            finalURI = finalURI.map { |b| b.downcase }  # make case insensitive search
            h["webPages"]["value"].each do |p| # for each matching pge do
              if finalURI.include?(p["url"].downcase) # compare to the final URI from the Utils::fetch routine (the page of metadata)
                output.comment << "SUCCESS: found a search record referencing #{p["url"]} based on a keyword search against Bing.\n  "
                output.score = "pass"
              end
            end
            unless output.score == "pass"
              output.comment << "INFO: No results from Bing included any of #{finalURI.map { |b| b.to_s }}.\n"
            end
          else
            output.comment << "INFO: No results from Bing using keywords #{keywords}.\n"
          end
        end
      end
    end

    unless output.score == "pass"
      output.comment << "FAILURE: Was unable to discover the metadata record by search in Bing using any method\n"
    end

    return output.createEvaluationResponse
  end

  def callBing(phrase)
    warn "Calling Bing with phrase #{phrase}\n\n"
    phrase = phrase.dup if phrase.frozen?
    phrase.gsub!(/https?\:\/\/[^\,]+/, "")  # need to eliminate URLs that appear as keywords
    uri = "https://api.cognitive.microsoft.com"
    path = "/bing/v7.0/search"

    acceskey = ENV["BING_API"]

    if accessKey.length != 32
      warn "Invalid Bing Search API subscription key!"
      warn "Please add this to your environment."
      abort
    end
    #	escapedphrase = Addressable::URI.encode(phrase)
    escapedphrase = CGI.escape(phrase)
    if escapedphrase.length > 1500
      escapedphrase = escapedphrase[0..1500] # microsoft suggested maximum query length
      match = escapedphrase.match(/(.*)(\%.*)/)  # trim off any partially escaped things at the end
      escapedphrase = match[1] if match[1]
    end

    uri = URI(uri + path + "?q=#{escapedphrase}&count=50")
    #warn "HTTP URI: #{uri}"

    request = Net::HTTP::Get.new(uri)
    request["Ocp-Apim-Subscription-Key"] = accessKey

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") do |http|
      http.request(request)
    end
    #warn "HTTP response: #{response.inspect}"
    return response.body
  end

  def self.fc_searchable_api
    schemas = { "subject" => ["string", "the GUID being tested"] }

    api = OpenAPI.new(title: self.fc_searchable_meta[:testname],
                      description: self.fc_searchable_meta[:description],
                      tests_metric: self.fc_searchable_meta[:metric],
                      version: self.fc_searchable_meta[:testversion],
                      applies_to_principle: self.fc_searchable_meta[:principle],
                      path: self.fc_searchable_meta[:testid],
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
