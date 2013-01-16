class CancerKaryotype < ActiveRecord::Base
  set_table_name 'cancer_karyotype'
  has_many :karyotypeses
  has_many :cancers
end
