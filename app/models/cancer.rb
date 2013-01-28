class Cancer < ActiveRecord::Base
  self.table_name = 'cancer'

  has_and_belongs_to_many :karyotypes

end
