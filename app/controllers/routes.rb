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
    ts = Dir[File.dirname(__FILE__) + '/../tests/*.rb']
    @tests = ts.map { |t| t.match(%r{.*/(\S+\.rb)$})[1] }
    erb :listtests
  end

  post '/tests/:id' do
    content_type :json
    id = params[:id]
    guid = ''
    if params['subject']
      guid = params['subject']
    else
      payload = JSON.parse(request.body.read)
      guid = payload['subject']
    end
    warn "now testing #{guid}"
    # begin
    @result = FAIRTest.send(id, guid: guid)
    # rescue StandardError
    #  @result = '{}'
    # end
    warn @result.class
    @result
  end

  get '/tests/:id' do
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

  get '/tests/:id/about' do
#    content_type 'application/ld+json'
    content_type 'text/turtle'
    id = params[:id]
    id += '_about'
    # begin
    graph = FAIRTest.send(id)
    # rescue StandardError
    #   graph = ''
    # end
#    graph.dump(:jsonld)
    graph.dump(:ttl)
  end

  before do
  end
end
