require 'active_record'
require 'rubygems'
require 'cytogenetics'
require 'logger'
require 'yaml'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")



dir = "/Users/skillcoyne/Data/sky-cgh"
time = Time.new
date = "#{time.day}#{time.month}#{time.year}"


log = Logger.new("#{dir}/logs/#{date}karyotype-resource.log")
log.datetime_format = "%M"
log.level = Logger::INFO
Cytogenetics.logger = log



#bpf = File.open("#{dir}/breakpoints.#{date}.txt", 'w')
#bpf.write("Event\tBreakpoint\tChr\n")
#
#fragf = File.open("#{dir}/fragments.#{date}.txt", 'w')
#fragf.write("Chr\tFrom\tTo\n")


## Mitelman karyotypes
source = KaryotypeSource.find_by_sql("SELECT source_id FROM #{KaryotypeSource.table_name} WHERE source_short = 'mitelman'")[0]
sid = source[:source_id]
File.open("#{dir}/mitelman/mm-kary_cleaned.txt", 'r').each_with_index do |line, i|
  line.chomp!
  next if line.start_with? "#"
  puts "Reading  Mitelman karyotype # #{i}"
  log.info("Reading  Mitelman karyotype # #{i}: #{dir}/mm-karyotypes.txt")
  (mmkaryotype, c_long, c_short, refno, caseno) = line.split("\t")

  cnc = Cancer.find_by_sql("SELECT cancer_id FROM #{Cancer.table_name} WHERE cancer_short = '#{c_short}'")
  puts YAML::dump cnc
  #if cnc.length <= 0
  #  cnc = Cancer.new
  #  cnc.cancer = c_long
  #  cnc.cancer_short = c_short
  #  cnc.save
  #  cid = cnc.id
  #else
  #  cid = cnc[0][:cancer_id]
  #end

  begin
    kt = Cytogenetics.karyotype(mmkaryotype)
    puts kt.karyotype.join(",")
    #
    #ktmodel = Karyotypes.new
    #ktmodel.karyotype = mmkaryotype
    #ktmodel.source_id = sid
    #ktmodel.save
    #
    #ck = CancerKaryotype.new
    #ck.cancer_id = cid
    #ck.karyotype_id = ktmodel.id
    #ck.save



    #write_breakpoints(bpf, kt.report_breakpoints)
    #write_fragments(fragf, kt.report_fragments)
  rescue Cytogenetics::StructureError => gse
    log.info("#{gse.message}: Mitelman line #{i}")
    #rescue => error
    #  log.error("Failed to parse karyotype from Mitelman line #{i}: #{error.message}")
    #  log.error(error.backtrace)
    #  puts error.backtrace
  end
break if i > 5
end

