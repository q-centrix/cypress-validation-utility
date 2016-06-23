  # Be sure to restart your server when you modify this file.

require_relative "../../lib/cms_validators"
require_relative "../../lib/encounter_validator"

BUNDLES = {
  "2016" => HealthDataStandards::CQM::Bundle.find_by(version: /^2015\./) 
  # 2016 is the reporting year so we have to use the 2015.x.x bundle ("2015 bundle for the 2016 program year")
}


CAT1_VALIDATORS = [HealthDataStandards::Validate::Cat1Measure.instance]
CAT3_VALIDATORS = [HealthDataStandards::Validate::Cat3Measure.instance, HealthDataStandards::Validate::Cat3PerformanceRate.instance]


VALIDATOR_NAMES = {"HealthDataStandards::Validate::CDA" => "CDA",
                   "HealthDataStandards::Validate::Cat1" => "QRDA",
                   "HealthDataStandards::Validate::Cat1R2" => "QRDA",
                   "HealthDataStandards::Validate::Cat3" => "QRDA",
                   "CypressValidationUtility::Validate::EPCat1_2016" => "CMS",
                   "CypressValidationUtility::Validate::EPCat3_2016" => "CMS",
                   "CypressValidationUtility::Validate::EHCat1_2016" => "CMS",
                   "HealthDataStandards::Validate::DataValidator" => "Value Sets",
                   "HealthDataStandards::Validate::Cat1Measure" => "Measures",
                   "HealthDataStandards::Validate::Cat3Measure" => "Measures",
                   "HealthDataStandards::Validate::Cat3PerformanceRate" => "Performance Rate",
                   "CypressValidationUtility::Validate::Cat3PopulationValidator" => "Populations",
                   "CypressValidationUtility::Validate::ValuesetCategoryValidator" => "Valueset Category",
                   "CypressValidationUtility::Validate::CCNValidator" => "Reporting",
                   "CypressValidationUtility::Validate::ProgramValidator" => "CMS Program",
                   "CypressValidationUtility::Validate::MeasurePeriodValidator" => "Measure Period"}

VALIDATOR_CATEGORIES = { qrda: 'QRDA Errors', reporting: 'Reporting Errors', submission: 'Submission Errors' }

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
