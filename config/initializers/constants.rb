  # Be sure to restart your server when you modify this file.

require_relative "../../lib/cms_validators"
require_relative "../../lib/encounter_validator"

BUNDLES = {
  "2016" => HealthDataStandards::CQM::Bundle.find_by(version: "2.7.0"),
  "2015" => HealthDataStandards::CQM::Bundle.find_by(version: "2.6.0")
}


CAT1_VALIDATORS = [HealthDataStandards::Validate::Cat1Measure.instance]
CAT3_VALIDATORS = [HealthDataStandards::Validate::Cat3Measure.instance, HealthDataStandards::Validate::Cat3PerformanceRate.instance]


VALIDATOR_NAMES = {HealthDataStandards::Validate::CDA => "CDA",
                   HealthDataStandards::Validate::Cat1 => "QRDA",
                   HealthDataStandards::Validate::Cat1R2 => "QRDA",
                   HealthDataStandards::Validate::Cat3 => "QRDA",
                   CypressValidationUtility::Validate::EPCat1 => "CMS",
                   CypressValidationUtility::Validate::EPCat3 => "CMS",
                   CypressValidationUtility::Validate::EHCat1 => "CMS",
                   CypressValidationUtility::Validate::EPCat1_2016 => "CMS",
                   CypressValidationUtility::Validate::EPCat3_2016 => "CMS",
                   CypressValidationUtility::Validate::EHCat1_2016 => "CMS",
                   HealthDataStandards::Validate::DataValidator => "Value Sets",
                   HealthDataStandards::Validate::Cat1Measure => "Measures",
                   HealthDataStandards::Validate::Cat3Measure => "Measures",
                   HealthDataStandards::Validate::Cat3PerformanceRate => "Performance Rate"}

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