require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'simplecov'

# Suppress warnings during tests
$VERBOSE = nil

begin
  require_relative 'support/rack_test_helper'
rescue LoadError => e
  raise "Failed to load spec/support/rack_test_helper.rb: #{e.message}"
end

SimpleCov.start

ENV['RACK_ENV'] = 'test'
ENV['TEST_PROTOCOL'] = 'http'
ENV['TEST_HOST'] = 'localhost:8282'
ENV['TEST_PATH'] = '/tests/'
ENV['FAIRSHARING_KEY'] = 'dummy-fairsharing-key'
ENV['BING_API'] = 'test_bing_api_key'

require File.expand_path('../app/controllers/application_controller', __dir__)

TEST_IDS = Dir.glob(File.join(File.dirname(__FILE__), '../../app/tests/*.rb'))
              .map { |f| File.basename(f, '.rb') }
              .reject { |f| f == 'env' }

class ErrorModel
  include Swagger::Blocks
  swagger_schema :ErrorModel do
    key :required, [:code, :message]
    property :code do
      key :type, :integer
      key :format, :int32
    end
    property :message do
      key :type, :string
    end
  end
end

module FAIRTestStub
  def self.send(method_name, **args)
    base_id = method_name.to_s.sub(/_(about|api)$/, '')
    if TEST_IDS.include?(base_id)
      case method_name.to_s
      when /_about$/
        graph = RDF::Graph.new
        graph << [RDF::URI.new("http://localhost:8282/tests/#{base_id}"), RDF::URI.new("http://semanticscience.org/resource/SIO_000233"), RDF::URI.new("https://doi.org/10.25504/FAIRsharing.EwnE1n")]
        graph << [RDF::URI.new("http://localhost:8282/tests/#{base_id}"), RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::URI.new("http://www.w3.org/ns/dcat#DataService")]
        graph << [RDF::URI.new("http://localhost:8282/tests/#{base_id}"), RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), RDF::URI.new("https://w3id.org/ftr#Test")]
        graph
      when /_api$/
        { swagger: '2.0', info: { title: "Test API #{base_id}" } }.to_json
      else
        {
          '@graph' => [
            { '@type' => 'ftr:TestExecutionActivity', '@id' => 'exec1', 'prov:wasAssociatedWith' => { '@id' => base_id }, 'prov:generated' => { '@id' => 'result1' } },
            { '@id' => base_id, 'sio:SIO_000233' => 'metric1' },
            { '@id' => 'result1', 'prov:value' => { '@value' => 'pass' } }
          ]
        }.to_json
      end
    else
      raise StandardError, "invalid test ID: #{base_id}"
    end
  end
end

module FAIRChampion
  module HarvesterStub
    def self.get_tests_metrics(tests:)
      tests.map { |t| { test: t, metrics: { score: 100, name: "Mock #{t}" } } }
    end
  end
end

module Swagger
  module Blocks
    def self.build_root_json(classes)
      {
        swagger: '2.0',
        info: {
          version: '1.0.0',
          title: 'FAIR Core Tests',
          description: 'The core set of FAIR tests used by the FAIR Champion evaluation platform',
          termsOfService: 'https://example.org',
          contact: { name: 'Mark D. Wilkinson' },
          license: { name: 'MIT' }
        },
        schemes: ['http'],
        host: 'localhost:8282',
        basePath: '/tests/'
      }
    end
  end
end

WebMock.stub_request(:any, %r{http://(evaluator-tika|localhost):9998/.*}).to_return(
  status: 200,
  body: { extracted: 'mocked Tika response' }.to_json,
  headers: { 'Content-Type' => 'application/json' }
)

WebMock.stub_request(:post, 'https://api.fairsharing.org/graphql').to_return(
  status: 200,
  body: { data: { fairsharingRecord: { id: '10.25504/FAIRsharing.EwnE1n', name: 'Mock FAIRsharing Record' } } }.to_json,
  headers: { 'Content-Type' => 'application/json' }
)

WebMock.stub_request(:get, %r{http://localhost:8282/tests/.*}).to_return do |request|
  test_id = request.uri.path.split('/').last
  if TEST_IDS.include?(test_id)
    {
      status: 200,
      body: [
        { '@id' => "http://localhost:8282/tests/#{test_id}",
          'http://semanticscience.org/resource/SIO_000233' => [{ '@id' => 'https://doi.org/10.25504/FAIRsharing.EwnE1n' }],
          '@type' => ['http://www.w3.org/ns/dcat#DataService', 'https://w3id.org/ftr#Test'] }
      ].to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  else
    {
      status: 404,
      body: { error: "invalid test ID: #{test_id}" }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  end
end

WebMock.stub_request(:get, %r{http://localhost:8282/tests/.*/api}).to_return do |request|
  test_id = request.uri.path.split('/')[-2]
  if TEST_IDS.include?(test_id)
    {
      status: 200,
      body: { swagger: '2.0', info: { title: "Test API #{test_id}" } }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  else
    {
      status: 404,
      body: { error: "invalid test ID: #{test_id}" }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include RackTestHelper

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc'

  config.before(:each) do
    Sinatra::Application.reset!
    allow(Dir).to receive(:[]).with(File.join(File.dirname(__FILE__), '../../app/tests/*.rb')).and_return(
      TEST_IDS.map { |id| File.join(File.dirname(__FILE__), "../../app/tests/#{id}.rb") }
    )
    # Stub Dir.[] for Docker path
    allow(Dir).to receive(:[]).with(%r{.*/app/controllers/\.\./tests/\*.rb}).and_return(
      TEST_IDS.map { |id| "/server/app/tests/#{id}.rb" }
    )
    allow(FAIRTest).to receive(:send).and_call_original
    TEST_IDS.each do |test_id|
      allow(FAIRTest).to receive(:send).with(test_id, anything).and_return(FAIRTestStub.send(test_id))
      allow(FAIRTest).to receive(:send).with("#{test_id}_about", anything).and_return(FAIRTestStub.send("#{test_id}_about"))
      allow(FAIRTest).to receive(:send).with("#{test_id}_api", anything).and_return(FAIRTestStub.send("#{test_id}_api"))
    end
    allow(FAIRTest).to receive(:send).with(anything, anything) do |method_name, *args|
      FAIRTestStub.send(method_name)
    end
    allow(FAIRChampion::Harvester).to receive(:get_tests_metrics).and_return(FAIRChampion::HarvesterStub.get_tests_metrics(tests: TEST_IDS))
  end
end

def app
  ApplicationController
end