class OpenAPI
  attr_accessor :title, :tests_metric, :description, :indicator,
                :organization, :org_url, :version, :creator,
                :responsible_developer, :email, :developer_ORCiD, :protocol,
                :host, :basePath, :path, :response_description, :schemas

  def initialize(meta:)
    indics = [meta[:indicators]] unless meta[:indicators].is_a? Array
    @title = meta[:title]
    @tests_metric = meta[:tests_metric]
    @description = meta[:description]
    @indicator = indics.first
    @version = meta[:version]
    @organization = meta[:organization]
    @org_url = meta[:org_url]
    @responsible_developer = meta[:responsible_developer]
    @email = meta[:email]
    @creator = meta[:creator]
    @host =  meta[:host]
    @protocol =  meta[:protocol]
    @basePath =  meta[:basePath]
    @path = meta[:path]
    @response_description = meta[:response_description]
    @schemas = meta[:schemas]
  end

  def get_api
    message = <<~"EOF_EOF"
      swagger: '2.0'
      info:
       version: '#{version}'
       title: "#{title}"
       x-tests_metric: '#{tests_metric}'
       description: >-
         #{description}
       x-applies_to_principle: "#{indicator}"
       contact:
        x-organization: "#{organization}"
        url: "#{org_url}"
        name: '#{responsible_developer}'
        x-role: "responsible developer"
        email: #{email}
        x-id: '#{creator}'
      host: #{host}
      basePath: #{basePath}
      schemes:
        - #{protocol}
      paths:
       #{path}:
        post:
         parameters:
          - name: content
            in: body
            required: true
            schema:
              $ref: '#/definitions/schemas'
         consumes:
           - application/json
         produces:#{'  '}
           - application/json
         responses:
           "200":
             description: >-
              #{response_description}
      definitions:
        schemas:
          required:
    EOF_EOF

    schemas.each_key do |key|
      message += "     - #{key}\n"
    end
    message += "    properties:\n"
    schemas.each_key do |key|
      message += "        #{key}:\n"
      message += "          type: #{schemas[key][0]}\n"
      message += "          description: >-\n"
      message += "            #{schemas[key][1]}\n"
    end

    message
  end
end
