class KaryotypeSource < ActiveRecord::Base
  set_table_name 'karyotype_source'

  has_many :karyotypeses

  # attr_accessible :title, :body
end
