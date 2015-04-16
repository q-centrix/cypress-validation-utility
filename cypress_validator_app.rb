require "sinatra/base"
require "sinatra/reloader"
require "sinatra/assetpack"
require 'sass_paths'
require "sass"
require "pry"
require "health-data-standards"
require_relative "./lib/cms_validators"

Mongoid.load!("mongoid.yml")

class CypressValidatorApp < Sinatra::Base
  register Sinatra::AssetPack

  configure :development do
    register Sinatra::Reloader
  end

  SassPaths.append("#{CypressValidatorApp.root}/app/css")
  

  assets do
    serve '/fonts/',  from: 'app/fonts/'

    js :application, [
      '/js/vendor/jquery-1.11.1.min.js',
      '/js/vendor/bootstrap.js',
      '/js/vendor/modernizr-2.6.2-respond-1.1.0.min.js',
      '/js/vendor/jasny-bootstrap.js',
      '/js/cypress-navigator.js',
      '/js/vendor/h5f.min.js',
      '/js/main.js'
    ]

    css :application, [
      '/css/cypress_new.css', # includes bootstrap
      '/css/bootstrap-theme.css',
      '/css/vendor/jasny-bootstrap.css',
      '/css/main.css'
    ]

    js_compression :uglify
    css_compression :sass
  end

  helpers do

    VALIDATOR_NAMES = {HealthDataStandards::Validate::CDA => "CDA",
                       HealthDataStandards::Validate::Cat1 => "QRDA",
                       HealthDataStandards::Validate::Cat3 => "QRDA",
                       CypressValidationUtility::Validate::EPCat1 => "CMS",
                       CypressValidationUtility::Validate::EPCat3 => "CMS",
                       HealthDataStandards::Validate::ValuesetValidator => "Value Sets",
                       HealthDataStandards::Validate::Cat1Measure => "Measures",
                       HealthDataStandards::Validate::Cat3Measure => "Measures"}

      NODE_TYPES ={ 1 => :element ,
                    2 => :attribute ,
                    3 => :text,
                    4 => :cdata,
                    5 => :ent_ref,
                    6 => :entity,
                    7 => :instruction,
                    8 => :comment,
                    9 => :document,
                    10  => :doc_type,
                    11  => :doc_frag,
                    12  => :notaion}

    def node_type(type)
      return NODE_TYPES[type]
    end

    def validator_name(validator)
      VALIDATOR_NAMES[validator.class]
    end

    def validator_slug(validator)
      validator.class.name.underscore.gsub("/", "_")
    end

    def match_errors(upload)
      doc = upload.content
      uuid = UUID.new
      error_map = {}
      error_id = 0
      error_attributes = []
      locs = upload.errors.collect{|e| e.location}
      locs.compact!

      locs.each do |location|
        # Get rid of some funky stuff generated by schematron
        clean_location = location.gsub("[namespace-uri()='urn:hl7-org:v3']", '')
        node = doc.at_xpath(clean_location)
        if(node)
          elem = node
          if node.class == Nokogiri::XML::Attr
            error_attributes << node
            elem = node.element
          end
          elem = elem.root if node_type(elem.type) == :document
          if elem

            unless elem['error_id']

              elem['error_id']= uuid.generate.to_s
            end
            error_map[location] = elem['error_id']
          end
        end
      end

      return error_map, error_attributes
    end
  end

  before do
    unless HealthDataStandards::CQM::Bundle.first
      raise "Please install a bundle in order to use the Cypress Validation Utility"
    end
  end

  get "/" do
    erb :index
  end

  post "/validate" do
    @upload = DocumentUpload.new(params[:file][:tempfile], params[:file_type], params[:program])
    # binding.pry
    erb :results
  end

class DocumentUpload

  attr_reader :doc_type, :program, :content

  def initialize(file, doc_type, program=nil)
    content_string = File.read(file)
    @content = Nokogiri::XML(content_string)
    
    #if the doc_type isn't passed in, see if we can find it in the document
    doc_type = get_doc_type if !doc_type
    @doc_type = doc_type

    #if the program isn't passed in, see if we can find it in the document
    program = get_program if !program
    @program = program

    @errors = validators.inject({}) do |errors, v|
      errors[v] = v.validate(content_string)
      errors
    end

  end

  def grouped_errors
    @errors
  end

  def errors
    @errors.values.flatten
  end

  private

  def get_doc_type
    # check to see if there's a node with the templateId for a QRDA Cat I
    if @content.at_xpath("//xmlns:templateId[@root='2.16.840.1.113883.10.20.24.1.1']")
      return "cat1"
    #if it's not a cat1, check to see if there's a node with the templateId for a Cat 3
    elsif @content.at_xpath("//xmlns:templateId[@root='2.16.840.1.113883.10.20.27.1.1']")
      return "cat3"
    #if it's neither of these, something's probably wrong
    else
      raise "Document doesn't appear to be a QRDA Cat 1 or Cat 3"
    end
  end

  def get_program 
    #xpath for informationRecipient, which is where CMS wants the code for the program
    prog = @content.at_xpath("//xmlns:informationRecipient/xmlns:intendedRecipient/xmlns:id/@extension")

    #If it's not there, raise an error
    if !prog
      return nil
    end

    #Figure out if the program is EP or EH
    return case prog.value
    when "CPC","PQRS_MU_INDIVIDUAL","PQRS_MU_GROUP","MU_ONLY"
      "ep"
    when "HQR_EHR","HQR_IQR","HQR_EHR_IQR"
      "eh"
    else
      #If the program name doesn't exist, return nil
      nil
    end
  end

  def validators
    return @validators if @validators

    @validators = []
    val_class = case @doc_type
    when "cat1"
      bundle = HealthDataStandards::CQM::Bundle.first
      @validators << HealthDataStandards::Validate::ValuesetValidator.new(bundle)
      @validators << HealthDataStandards::Validate::Cat1Measure.instance
      if @program.downcase == "ep"
        CypressValidationUtility::Validate::EPCat1
      elsif @program.downcase == "eh"
        CypressValidationUtility::Validate::EHCat1
      else
        HealthDataStandards::Validate::Cat1
      end
    when "cat3"
      @validators << HealthDataStandards::Validate::Cat3Measure.instance
      if @program.downcase == "ep"
        CypressValidationUtility::Validate::EPCat3
      elsif @program.downcase == "none"
        HealthDataStandards::Validate::Cat3
      else
        raise "Cannot validate an EH QRDA Category III file"
      end
    else
      raise "Invalid doc_type param: Must be one of (cat1, cat3)"
    end

    @validators << val_class.instance
    @validators << HealthDataStandards::Validate::CDA.instance  
  end

end

end
