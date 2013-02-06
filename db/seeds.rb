

KaryotypeSource.create([{source: 'Mitelman',
                         source_short: 'mitelman',
                         url: 'http://cgap.nci.nih.gov/Chromosomes/Mitelman',
                         description: 'Mitelman Database of Chromosome Aberrations and Gene Fusions in Cancer',
                         date_accessed: '2012-11-26', karyotype_count: 0},
                        {source: 'NCBI SKY-FISH',
                         source_short: 'ncbi',
                         url: 'http://www.ncbi.nlm.nih.gov/sky/',
                         description: 'SKY/FISH public data',
                         date_accessed: '2012-11-12', karyotype_count: 0},
                        {source: 'University of Cambridge CGP',
                         source_short: 'cam',
                         url: 'http://www.path.cam.ac.uk/~pawefish/',
                         description: 'SKY Karyotypes and FISH analysis of Epithelial Cancer Cell Lines',
                         date_accessed: '2012-10-22', karyotype_count: 0},
                        {source: 'NCI Fredrick National Laboratory',
                         source_short: 'ncifnl',
                         url: 'http://home.ncifcrf.gov/CCR/60SKY/new/demo1.asp',
                         description: 'SKY Karyotypes of NCI60 cell lines',
                         date_accessed: '2013-01-16', karyotype_count: 0}])


File.open("#{Dir.pwd}/db/cell_lines.txt", 'r').each do |line|
  line.chomp!
  CellLine.create(:name => line)
end

File.open("#{Dir.pwd}/db/chromosome_bands.txt", 'r').each do |line|
  line.chomp!
  next if line.length <= 0 or line.eql?("") or line.start_with?"#"
  (chr, band, start, stop) = line.split("\t")
  ChromosomeBands.create(:chromosome => chr.strip, :band => band.strip, :start => start.strip, :end => stop.strip)
end

## Add major bands

chrbands = ChromosomeBands.all
chrbands.each do |cb|
  if cb.band.match(/([q|p]\d+)\.\d+/)
    m = cb.band.match(/([q|p]\d+)/)
    band = m.captures.first
    c =  ChromosomeBands.where("chromosome = ? AND band LIKE ?", cb.chromosome, "%#{band}%").order(:start)
    ChromosomeBands.find_or_create_by_chromosome_and_band_and_start_and_end(cb.chromosome, band, c.first.start, c.last.end)
  end
end




File.open("#{Dir.pwd}/db/cancer_lookup.txt", 'r').each do |line|
  line.chomp!
  next if line.length <= 0 or line.eql?("")
  (name, translation) = line.split(",")
  CancerLookup.create(:name => name.strip, :translation => translation.strip)
end


