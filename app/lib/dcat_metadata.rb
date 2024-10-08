class DCAT_Record
  attr_accessor :title, :tests_metric, :description, :applies_to_principle, :organization, :org_url, :version
  attr_accessor :responsible_developer, :email, :developer_ORCiD, :protocol,
  attr_accessor :theme

  def initialize(title:, tests_metric:, description:, applies_to_principle:, organization:, org_url:, responsible_developer:, 
    email:, developer_ORCiD:, protocol:, host:, basePath:, path:, response_description:, schemas:, version:, theme)

    @title = title
    @tests_metric = tests_metric
    @description = description 
    @applies_to_principle = applies_to_principle 
    @version = version 
    @organization = organization 
    @org_url = org_url 
    @responsible_develper = responsible_developer 
    @email = email 
    @developer_ORCiD = developer_ORCiD 
    @host = host 
    @protocol = protocol 
    @basePath = basePath 
    @path = path 
    @response_description = response_description 
    @schemas = schemas 
  end


  def get_dcat
    schema = RDF::Vocab::SCHEMA
    dcterms = RDF::Vocab::DC
    ftr = RDF::Vocabulary.new('https://w3id.org/ftr#')
    dct = RDF::Vocab::DCAT
    g = RDF::Graph.new

#triplify tests and rejects anything that is empty or nil  --> SAFE
# Test Unique Identifier	dcterms:identifier	Literal
Champion::Output.triplify_this(me, dcterms.identifier, identifier, g)

# Title/Name of the test	dcterms:title	Literal
Champion::Output.triplify_this(me, dcterms.title, title, g)

# Description	dcterms:description	Literal
Champion::Output.triplify_this(me, dcterms.description, description, g)

# Keywords	dcat:keyword	Literal
keywords.each do |kw|
  Champion::Output.triplify_this(me, dcat.keyword, kw, g)
end

# Test creator	dcterms:creator	dcat:Agent (URI)
Champion::Output.triplify_this(me, dcterms.description, creator, g)

# Dimension	ftr:indicator	
indicators.each do |ind|
  Champion::Output.triplify_this(me, ftr.indicator, ind, g)
end

# API description	dcat:endpointDescription	rdfs:Resource
Champion::Output.triplify_this(me, dcat.endpointDescription, end_desc, g)

# API URL	dcat:endpointURL	rdfs:Resource
Champion::Output.triplify_this(me, dcat.endpointURL, end_url, g)

# Source of the test	codemeta:hasSourceCode/schema:codeRepository/ doap:repository	schema:SoftwareSourceCode/URL
# TODO
Champion::Output.triplify_this(me, dcat.endpointDescription, end_desc, g)


# Functional Descriptor/Operation	dcterms:type	xsd:anyURI
Champion::Output.triplify_this(me, dcterms.type, dctype, g)


# License	dcterms:license	xsd:anyURI
Champion::Output.triplify_this(me, dcterms.license, license, g)

# Semantic Annotation	dcat:theme	xsd:anyURI
themes.each do |theme|
  Champion::Output.triplify_this(me, dcat:theme, theme, g)
end

# Version	dcat:version	rdfs:Literal
Champion::Output.triplify_this(me, dcat.version, version, g)

# Version notes	adms:versionNotes	rdfs:Literal
#Champion::Output.triplify_this(me, dcterms.license, license, g)
		
# Responsible	dcat:contactPoint	dcat:Kind (includes Individual/Organization)
# Metadata thas describes an Organization		
# Organization name	dcterms:publisher/foaf:name	xsd:string
# Organization URL	[part of vcard:Organization] vcard:url	xsd:anyURI
		
# Metadata that describes a Person/Agent/Kind		
# Responsable/owner name	dcat:contactPoint/vcard:fn	dcat:Kind (includes Individual/Organization)
# Responsible/owner id	dcat:contactPoint/vcard:hasUID (or dcterms:identifier)	
# Responsible/Email to contact	dcat:contactPoint/vcard:email	rdf:Resource

  
  end
end