class KaryotypeSource < ActiveRecord::Base
  self.table_name = 'karyotype_source'

  has_many :karyotypes


end
