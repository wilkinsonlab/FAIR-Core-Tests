require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require 'simplecov'
require_relative 'support/rack_test_helper'

SimpleCov.start

ENV['RACK_ENV'] = 'test'
ENV['TEST_PROTOCOL'] = 'http'
ENV['TEST_HOST'] = 'tests:4567'
ENV['TEST_PATH'] = '/tests/'
ENV['FAIRSHARING_KEY'] = 'test_fairsharing_key'
ENV['BING_API'] = 'test_bing_api_key'

require File.expand_path('../../app/controllers/application_controller', __dir__)

# Dynamically generate TEST_IDS from app/tests/*.rb, excluding non-Ruby files
TEST_IDS = Dir.glob(File.join(File.dirname(__FILE__), '../../app/tests/*.rb'))
              .map { |f| File.basename(f, '.rb') }
              .reject { |f| f == 'env' }

# Stub ErrorModel for Swagger
class ErrorModel
  include Swagger::Blocks
  swagger_schema :ErrorModel do
    key :required, %i[code message]
    property :code do
      key :type, :integer
      key :format, :int32
    end
    property :message do
      key :type, :string
    end
  end
end

# Stub external dependencies
module FAIRTest
  def self.send(method_name, **args)
    base_id = method_name.to_s.sub(/_(about|api)$/, '')
    raise StandardError, "Invalid test ID: #{base_id}" unless TEST_IDS.include?(base_id)

    case method_name.to_s
    when /_about$/
      RDF::Graph.new # Stub RDF graph for /tests/:id
    when /_api$/
      "swagger: '2.0'\ninfo:\n  title: Test API" # Stub Swagger YAML for /tests/:id/api
    else
      # Stub JSON result for /assess/test/:id
      {
        '@graph' => [
          { '@type' => 'ftr:TestExecutionActivity', '@id' => 'exec1',
            'prov:wasAssociatedWith' => { '@id' => base_id }, 'prov:generated' => { '@id' => 'result1' } },
          { '@id' => base_id, 'sio:SIO_000233' => 'metric1' },
          { '@id' => 'result1', 'prov:value' => { '@value' => 'pass' } }
        ]
      }.to_json
    end
  end
end

module FAIRChampion
  module Harvester
    def self.get_tests_metrics(tests:)
      tests.map { |t| { test: t, metrics: { score: 100 } } }
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
        host: ENV['HARVESTER'] || 'localhost:4567',
        basePath: '/tests/'
      }
    end
  end
end

# Stub Tika HTTP requests
Webmock.stub_request(:any, %r{http://evaluator-tika:9998/.*}).to_return(
  status: 200,
  body: { extracted: 'mocked Tika response' }.to_json,
  headers: { 'Content-Type' => 'application/json' }
)

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include RackTestHelper

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
