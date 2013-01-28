class Aberration < ActiveRecord::Base
  self.table_name = 'aberrations'

  belongs_to :karyotype_aberration


end
