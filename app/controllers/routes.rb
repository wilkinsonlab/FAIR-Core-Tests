 # frozen_string_literal: false

def set_routes(classes: allclasses)
  set :server_settings, timeout: 180
  set :public_folder, 'public'
  set :port, 8282

  get '/' do
    content_type :json
    response.body = JSON.dump(Swagger::Blocks.build_root_json(classes))
  end

  get '/tests' do
    redirect "/tests/"
  end
  get '/tests/' do
    ts = Dir[File.dirname(__FILE__) + '/../tests/*.rb']
    @tests = ts.map { |t| t.match(%r{.*/(\S+)\.rb$})[1] }
    @labels = FAIRChampion::Harvester.get_tests_metrics(tests: @tests)
    erb :listtests
  end

  post '/tests/assess/test/:id' do
    fullpath = "#{request.fullpath}"
    fullpath.gsub!(/^\/tests/, "")  # due to new API calls that must befin with "assess" instead of "tests"
    status 307
    headers['Location'] = fullpath
    ''  
  end

  post '/assess/test/:id' do
    content_type :json
    id = params[:id]
    guid = ''
    if params['resource_identifier']
      guid = params['resource_identifier']
    else
      payload = JSON.parse(request.body.read)
      guid = payload['resource_identifier']
    end
    warn "now testing #{guid}"
    # begin
    @result = FAIRTest.send(id, guid: guid)  # @result is a json STRING!
    # rescue StandardError
    #  @result = '{}'
    # end
    # warn @result.class
    request.accept.each do |type|
      case type.to_s
      when 'text/html', 'application/xhtml+xml'
        content_type :html
        data = JSON.parse(@result)
        @test_execution = data['@graph'].find { |g| g['@type'] == 'ftr:TestExecutionActivity' }
        @test = data['@graph'].find { |g| g['@id'] == @test_execution['prov:wasAssociatedWith']['@id'] }
        @metric_implementation = @test['sio:SIO_000233'] # Extract SIO_000233
        @test_result = data['@graph'].find { |g| g['@id'] == @test_execution['prov:generated']['@id'] }
        @result_value = @test_result['prov:value']['@value'] # Extract pass/fail
        halt erb :testresult
      when 'text/json', 'application/json', 'application/ld+json'
        content_type :json
        halt @result
      else 
        warn "type is #{type}"
      end
    end
    error 406
  end




  # ============================= GET ----
  # ============================= GET ----
  # ============================= GET ----
  # ============================= GET ----


  get '/tests/:id' do  # returns DCAT
    content_type 'text/turtle'
    content_type 'application/ld+json'
    id = params[:id]
    id += '_about'
    # begin
    graph = FAIRTest.send(id)
    # rescue StandardError
    #   graph = ''
    # end
    graph.dump(:jsonld)
#    graph.dump(:ttl)
  end


  get '/tests/:id/api' do  # return swagger
    content_type 'application/openapi+yaml'
    id = params[:id]
    id += '_api'
    # begin
    @result = FAIRTest.send(id)
    # rescue StandardError
    #  @result = ''
    # end
    @result
  end

      # get '/tests/:id' do
  #   content_type 'application/openapi+yaml'
  #   id = params[:id]
  #   id += '_api'
  #   # begin
  #   @result = FAIRTest.send(id)
  #   # rescue StandardError
  #   #  @result = ''
  #   # end
  #   @result
  # end

#   get '/tests/:id/about' do
# #    content_type 'application/ld+json'
#     content_type 'text/turtle'
#     id = params[:id]
#     id += '_about'
#     # begin
#     graph = FAIRTest.send(id)
#     # rescue StandardError
#     #   graph = ''
#     # end
# #    graph.dump(:jsonld)
#     graph.dump(:ttl)
#   end

  before do
  end
end
