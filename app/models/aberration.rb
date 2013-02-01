class Aberration < ActiveRecord::Base
  self.table_name = 'aberrations'

  has_and_belongs_to_many :karyotypes
  has_and_belongs_to_many :breakpoints

end
