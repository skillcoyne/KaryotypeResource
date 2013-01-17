class Karyotypes < ActiveRecord::Base
  set_table_name 'karyotypes'

  belongs_to :karyotype_source
  has_one :cell_line

  #attr_accessible :id, :karyotype, :source

  ## TODO should cross ref with the karyotype_source table
  def Karyotypes.get_karyotypes(*args)
    if args.length > 0
      ids = args[:ids] if args[:ids]
      source = args[:source] if args[:source]
      cancers = args[:cancer] if args[:cancer]
    end
    karyotypes = find(:all)
    return karyotypes
  end

end


#books = find(:all, :conditions => "pub_type = 'book'", :order => 'year')
#    books.each do |b|
#      b.citation = b.create_citation
#    end
#    return books
#  end

