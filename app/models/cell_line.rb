class CellLine < ActiveRecord::Base

  self.table_name =  'cell_lines'

  has_one :karyotype

end
