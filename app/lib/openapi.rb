class OpenAPI
  attr_accessor :title, :metric, :description, :indicator, :testid,
                :organization, :org_url, :version, :creator,
                :responsible_developer, :email, :developer_ORCiD, :protocol,
                :host, :basePath, :path, :response_description, :schemas

  def initialize(meta:)
    indics = [meta[:indicators]] unless meta[:indicators].is_a? Array
    @testid = meta[:testid]
    @title = meta[:testname]
    @version = meta[:testversion]
    @metric = meta[:metric]
    @description = meta[:description]
    @indicator = indics.first
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

openapi: 3.0.0
info:
  version: "#{version}"
  title: "#{title}"
  x-tests_metric: "#{metric}"
  description: >-
    "#{description}"
  x-applies_to_principle: "#{indicator}"
  contact:
    x-organization: "#{organization}"
    url: "#{org_url}"
    name: "#{responsible_developer}"
    x-role: responsible developer
    email: "#{email}"
    x-id: "#{creator}"
paths:
  "/#{testid}":
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/schemas"
        required: true
      responses:
        "200":
          description:  >-
            #{response_description}
servers:
  - url: "#{protocol}://#{host}#{basePath}"
components:
  schemas:
    schemas:
      required:
        - subject
      properties:
        subject:
          type: string
          description: the GUID being tested

EOF_EOF

    message
  end
end
