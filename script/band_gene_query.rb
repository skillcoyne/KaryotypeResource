require 'rubygems'
require 'biomart'
require 'active_record'
require 'fileutils'
require 'simple_matrix'
require 'yaml'


require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

chrs = Array(1..22)
chrs << 'X'
chrs << 'Y'

biomart = Biomart::Server.new("http://www.ensembl.org/biomart")
hsgene = biomart.datasets['hsapiens_gene_ensembl']

attributes = [
    'ensembl_gene_id',
    'external_gene_id',
    'gene_biotype',
    'start_position',
    'end_position',
    'band'
]


m = SimpleMatrix.new
m.colnames = ['chr', 'band', 'start', 'end', 'gene.count']

i = 0
chrs.each do |chr|
  bands = ChromosomeBands.find_all_major_bands(chr)

puts chr
  bands.each do |band|
    puts band
    gene_count = 0

    filters =  { 'chromosome_name' => chr,
                 'chromosomal_region' => ["#{chr}:#{band.start}-#{chr}:#{band.end}"],
                 'status' => ["KNOWN"] }

    results = hsgene.search(
        :filters => filters,
        :attributes => attributes,
        :process_results => true
    ).select! { |e| e['gene_biotype'].eql? 'protein_coding' }

    unless results.nil?
      gene_count = results.length
    end

    m.add_row(i, [chr, band.band, band.start, band.end, gene_count] )
    i += 1
  end

end

outdir = "#{Dir.home}/Data/sky-cgh/output"
m.write("#{outdir}/band_genes.txt", :rownames => false)

m.write(nil, :rownames => false)



