class Karyotype < ActiveRecord::Base
  self.table_name = 'karyotypes'

  has_and_belongs_to_many :breakpoints
  has_and_belongs_to_many :cancers
  has_and_belongs_to_many :aberrations

  belongs_to :karyotype_source
  belongs_to :cell_line

end


