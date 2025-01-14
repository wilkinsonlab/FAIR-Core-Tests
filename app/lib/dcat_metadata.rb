module ChampionDCAT
  class DCAT_Record
    attr_accessor :identifier, :testname, :description, :keywords, :creator,
                  :indicators, :end_desc, :end_url, :dctype, :testid,
                  :license, :themes, :testversion, :implementations,
                  :organizations, :individuals, :protocol, :host, :basePath

    include RDF
    extend Forwardable
    require_rel './output.rb'

    def initialize(meta:)
      indics = [meta[:indicators]] unless meta[:indicators].is_a? Array
      @testid = meta[:testid]
      @title =  meta[:testname]
      @description = meta[:description]
      @keywords = meta[:keywords]
      @keywords = [@keywords] unless @keywords.is_a? Array
      @creator =  meta[:creator]
      @indicators = indics
      @end_desc = meta[:end_desc]
      @end_url = meta[:end_url]
      @dctype = meta[:dctype] || "http://edamontology.org/operation_2428"
      @license = meta[:license]
      @themes = meta[:themes]
      @themes = [@themes] unless @themes.is_a? Array
      @version = meta[:testversion]
      @organizations = meta[:organizations]
      @individuals = meta[:individuals]
      @protocol =  meta[:protocol]
      @host = meta[:host]
      @basePath = meta[:basePath]
      cleanhost = @host.gsub(/\//, "")
      cleanpath = @basePath.gsub(/\//, "")
      @end_url = "#{protocol}://#{cleanhost}/#{cleanpath}/#{testid}"
      @end_desc = "#{protocol}://#{cleanhost}/#{cleanpath}/#{testid}"
      @identifier = @end_url
      @implementations = [@end_url]
    end

    def get_dcat
      schema = RDF::Vocab::SCHEMA
      dcterms = RDF::Vocab::DC
      vcard = RDF::Vocab::VCARD
      dcat = RDF::Vocab::DCAT
      sio = RDF::Vocabulary.new('http://semanticscience.org/resource/')
      ftr = RDF::Vocabulary.new('https://w3id.org/ftr#')
      vcard = RDF::Vocabulary.new('http://www.w3.org/2006/vcard/ns#')
      g = RDF::Graph.new
      me = "#{identifier}/about"

      FAIRChampion::Output.triplify(me, RDF.type, dcat.DataService, g)

      # triplify tests and rejects anything that is empty or nil  --> SAFE
      # Test Unique Identifier	dcterms:identifier	Literal
      FAIRChampion::Output.triplify(me, dcterms.identifier, identifier, g)

      # Title/Name of the test	dcterms:title	Literal
      FAIRChampion::Output.triplify(me, dcterms.title, title, g)

      # Description	dcterms:description	Literal
      # descriptions.each do |d|
      #   FAIRChampion::Output.triplify(me, dcterms.description, d, g)
      # end
      FAIRChampion::Output.triplify(me, dcterms.description, description, g)

      # Keywords	dcat:keyword	Literal
      keywords.each do |kw|
        FAIRChampion::Output.triplify(me, dcat.keyword, kw, g)
      end

      # Test creator	dcterms:creator	dcat:Agent (URI)
      FAIRChampion::Output.triplify(me, dcterms.creator, creator, g)

      # Dimension	ftr:indicator
      indicators.each do |ind|
        FAIRChampion::Output.triplify(me, dqv.inDimension, ind, g)
      end

      # API description	dcat:endpointDescription	rdfs:Resource
      FAIRChampion::Output.triplify(me, dcat.endpointDescription, end_desc, g)

      # API URL	dcat:endpointURL	rdfs:Resource
      FAIRChampion::Output.triplify(me, dcat.endpointURL, end_url, g)

      # Source of the test	codemeta:hasSourceCode/schema:codeRepository/ doap:repository	schema:SoftwareSourceCode/URL
      # TODO
      # FAIRChampion::Output.FAIRChampion::Output.triplify(me, dcat.endpointDescription, end_desc, g)

      # Functional Descriptor/Operation	dcterms:type	xsd:anyURI
      FAIRChampion::Output.triplify(me, dcterms.type, dctype, g)

      # License	dcterms:license	xsd:anyURI
      FAIRChampion::Output.triplify(me, dcterms.license, license, g)

      # Semantic Annotation	dcat:theme	xsd:anyURI
      themes.each do |theme|
        FAIRChampion::Output.triplify(me, dcat.theme, theme, g)
      end

      # Version	dcat:version	rdfs:Literal
      FAIRChampion::Output.triplify(me, RDF::Vocab::DCAT.to_s + 'version', version, g)

      # # Version notes	adms:versionNotes	rdfs:Literal
      # FAIRChampion::Output.FAIRChampion::Output.triplify(me, dcat.version, version, g)

      implementations.each do |i|
        FAIRChampion::Output.triplify(me, sio['SIO_000233'], i, g) # is implementation of
      end

      # Responsible	dcat:contactPoint	dcat:Kind (includes Individual/Organization)
      individuals.each do |i|
        # i = {name: "Mark WAilkkinson", "email": "asmlkfj;askjf@a;lksdjfas"}
        guid = SecureRandom.uuid
        cp = "urn:fairchampion:testmetadata:individual#{guid}"
        FAIRChampion::Output.triplify(me, dcat.contactPoint, cp, g)
        FAIRChampion::Output.triplify(cp, RDF.type, vcard.Individual, g)
        FAIRChampion::Output.triplify(cp, vcard.fn, i['name'], g)
        FAIRChampion::Output.triplify(cp, vcard.hasEmail, RDF::URI.new(i['email'].to_s), g)
      end

      organizations.each do |o|
        # i = {name: "CBGP", "url": "https://dbdsf.orhf"}
        guid = SecureRandom.uuid
        cp = "urn:fairchampion:testmetadata:org:#{guid}"
        FAIRChampion::Output.triplify(me, dcat.contactPoint, cp, g)
        FAIRChampion::Output.triplify(cp, RDF.type, vcard.Organization, g)
        FAIRChampion::Output.triplify(cp, vcard['organization-name'], o['name'], g)
        FAIRChampion::Output.triplify(cp, vcard.url, RDF::URI.new(o['url'].to_s), g)
      end
      g
    end
  end
end
