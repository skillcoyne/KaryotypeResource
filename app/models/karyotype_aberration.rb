class KaryotypeAberration < ActiveRecord::Base
  set_table_name 'karyotype_aberration'
  has_many :karyotypeses
  has_many :aberrationses
end
