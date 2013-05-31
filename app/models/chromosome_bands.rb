class ChromosomeBands < ActiveRecord::Base
  self.table_name = 'chromosome_bands'

  def self.find_all_major_bands(chr)
    bands = ChromosomeBands.where(:chromosome => chr).order("start")
    bands.delete_if{|b| b.band.match(/\.\d+/)}
    return bands
  end

end
