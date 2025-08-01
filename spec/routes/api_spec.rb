require 'spec_helper'

RSpec.describe 'API Routes' do
  let(:valid_test_id) { 'fc_data_authorization' }
  let(:invalid_test_id) { 'invalid_test' }

  describe 'OPTIONS /*' do
    it 'returns CORS headers and allowed methods' do
      options '/any/path'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(last_response.headers['Allow']).to eq('GET, PUT, POST, DELETE, OPTIONS')
      expect(last_response.headers['Access-Control-Allow-Headers']).to eq('Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token')
    end
  end

  describe 'GET /' do
    it 'returns Swagger JSON with FAIR Core Tests info' do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.content_type).to include('application/json')
      expect(json_response).to include(
        swagger: '2.0',
        info: hash_including(
          title: 'FAIR Core Tests',
          description: 'The core set of FAIR tests used by the FAIR Champion evaluation platform'
        )
      )
    end
  end

  describe 'GET /tests' do
    it 'redirects to /tests/' do
      get '/tests'
      expect(last_response).to be_redirect
      expect(last_response.location).to eq('http://example.org/tests/')
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  describe 'GET /tests/' do
    it 'renders test list with metrics' do
      get '/tests/'
      expect(last_response).to be_ok
      expect(last_response.content_type).to include('text/html')
      expect(last_response.body).to include('fc_data_authorization')
      expect(last_response.body).to include('fc_unique_identifier')
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  describe 'POST /tests/assess/test/:id' do
    it 'redirects to /assess/test/:id for valid test ID' do
      post "/tests/assess/test/#{valid_test_id}"
      expect(last_response.status).to eq(307)
      expect(last_response.headers['Location']).to eq("/assess/test/#{valid_test_id}")
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end

  describe 'POST /assess/test/:id' do
    context 'with JSON payload and JSON accept header' do
      it 'returns test result as JSON for valid test ID' do
        header 'Accept', 'application/json'
        post "/assess/test/#{valid_test_id}", { resource_identifier: 'guid1' }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response).to be_ok
        expect(last_response.content_type).to include('application/json')
        expect(json_response[:@graph]).to include(
          hash_including('@type' => 'ftr:TestExecutionActivity', '@id' => 'exec1')
        )
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end

      it 'raises error for invalid test ID' do
        allow(FAIRTest).to receive(:send).with(invalid_test_id, guid: 'guid1').and_raise(StandardError, "Invalid test ID: #{invalid_test_id}")
        header 'Accept', 'application/json'
        post "/assess/test/#{invalid_test_id}", { resource_identifier: 'guid1' }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(500)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end

    context 'with form params and HTML accept header' do
      it 'renders test result ERB template for valid test ID' do
        header 'Accept', 'text/html'
        post "/assess/test/#{valid_test_id}", { resource_identifier: 'guid1' }
        expect(last_response).to be_ok
        expect(last_response.content_type).to include('text/html')
        expect(last_response.body).to include('pass')
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end

    context 'with unsupported accept header' do
      it 'returns 406 error' do
        header 'Accept', 'text/plain'
        post "/assess/test/#{valid_test_id}", { resource_identifier: 'guid1' }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(406)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end
  end

  describe 'GET /tests/:id' do
    context 'with Turtle accept header' do
      it 'returns RDF graph as Turtle for valid test ID' do
        header 'Accept', 'text/turtle'
        get "/tests/#{valid_test_id}"
        expect(last_response).to be_ok
        expect(last_response.content_type).to include('text/turtle')
        expect(last_response.body).to be_a(String)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end

      it 'raises error for invalid test ID' do
        allow(FAIRTest).to receive(:send).with("#{invalid_test_id}_about").and_raise(StandardError, "Invalid test ID: #{invalid_test_id}")
        header 'Accept', 'text/turtle'
        get "/tests/#{invalid_test_id}"
        expect(last_response.status).to eq(500)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end

    context 'with JSON-LD accept header' do
      it 'returns RDF graph as JSON-LD for valid test ID' do
        header 'Accept', 'application/ld+json'
        get "/tests/#{valid_test_id}"
        expect(last_response).to be_ok
        expect(last_response.content_type).to include('application/json')
        expect(last_response.body).to be_a(String)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end
  end

  describe 'GET /tests/:id/api' do
    it 'returns Swagger YAML for valid test ID' do
      get "/tests/#{valid_test_id}/api"
      expect(last_response).to be_ok
      expect(last_response.content_type).to include('application/openapi+yaml')
      expect(last_response.body).to include("swagger: '2.0'")
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'raises error for invalid test ID' do
      allow(FAIRTest).to receive(:send).with("#{invalid_test_id}_api").and_raise(StandardError, "Invalid test ID: #{invalid_test_id}")
      get "/tests/#{invalid_test_id}/api"
      expect(last_response.status).to eq(500)
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end
  end
end