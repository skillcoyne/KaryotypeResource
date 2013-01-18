require 'active_record'
require 'rubygems'
require 'fileutils'
require 'cytogenetics'
require 'logger'

require 'yaml'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")


def create_karyotype_record(args)
  karyotype = args[:karyotype]
  source = args[:source]
  source_type = args[:source_type]
  cancer = args[:cancer]

  kt = Cytogenetics.karyotype(karyotype)

  ktmodel = Karyotypes.create(:karyotype => karyotype, :source_id => source.source_id, :source_type => source_type)

  cnc = Cancer.where(:cancer => cancer).first
  if cnc.nil?
    cnc = Cancer.new
    cnc.cancer = cancer
    cnc.save
  end
  CancerKaryotype.create(:karyotype_id => ktmodel.id, :cancer_id => cnc.id)

  kt.report_breakpoints.each do |bp|
    bps = Breakpoints.where(:breakpoint => bp.to_s).first
    if bps.nil?
      bps = Breakpoints.new
      bps.breakpoint = bp.to_s
      bps.save
    end

    bpk = BreakpointKaryotype.new
    bpk.breakpoint_id = bps.breakpoint_id
    bpk.karyotype_id = ktmodel.id
    bpk.save
  end

  kt.aberrations.each_pair do |ab_class, aberrations|
    aberrations.each do |a|
      abr = Aberrations.where(:aberration => a, :aberration_class => ab_class).first
      if abr.nil?
        abr = Aberrations.new
        abr.aberration_class = ab_class
        abr.aberration = a
        abr.save
      end
      KaryotypeAberration.create(:karyotype_id => ktmodel.id, :aberration_id => abr.aberration_id)
    end
  end

  return ktmodel.id
end

def cancer_name(cancer)
  cancer.chomp!
  cancer = cancer.split(",")[0]
  cancer = 'unknown' if (cancer.nil? or cancer.match(/N\/a|NA|N\/A/) or cancer.eql? "")
  cancer.downcase!
  cancer.sub!(/nos .*/, "") if cancer.match(/ nos /)
  cancer.lstrip!
  cancer.rstrip!
  cl = CancerLookup.where(:name => cancer).first
  cancer = cl.translation unless cl.nil?
  return cancer.capitalize
end

def mitelman(dir, log)
  File.open("#{dir}/mitelman/mm-kary_cleaned.txt", 'r').each_with_index do |line, i|
    line.chomp!
    next if line.start_with? "#"
    log.info "Reading  Mitelman karyotype # #{i}"
    #log.info("Reading  Mitelman karyotype # #{i}: #{dir}/mm-karyotypes.txt")
    (karyotype, morph, shortmorph, refno, caseno) = line.split(/\t/)

    begin
      create_karyotype_record(:karyotype => karyotype, :cancer => cancer_name(morph),
                              :source => KaryotypeSource.where("source_short = ?", 'mitelman').first,
                              :source_type => 'patient')
    rescue Cytogenetics::StructureError => gse
      log.error("#{gse.message}: Mitelman line #{i}")
      #rescue => error
      #  log.error("Failed to parse karyotype from Mitelman line #{i}: #{error.message}")
      #  log.error(error.backtrace)
      #  puts error.backtrace
    end
  end
end

def cambridge(dir, log)
  camdir = "#{dir}/path.cam.ac.uk"

  Dir.foreach(camdir) do |tissuedir|
    next if tissuedir.start_with?(".")
    next unless File.directory? "#{camdir}/#{tissuedir}"

    Dir.foreach("#{camdir}/#{tissuedir}") do |entry|
      next if entry.start_with?(".")
      next if entry.eql? "url.txt"
      file = "#{camdir}/#{tissuedir}/#{entry}"

      cl = CellLine.where(:cell_line => entry.sub(/\..*./, "")).first
      if cl.nil?
        cl = CellLine.create(:cell_line => entry.sub(/\..*./, ""))
      end

      log.info "Reading #{file}..."
      File.open(file, 'r').each_line do |karyotype|
        karyotype.chomp!
        next if karyotype.length <= 1

        begin
          kid = create_karyotype_record(:karyotype => karyotype, :cancer => tissuedir,
                                        :source => KaryotypeSource.where("source_short = ?", 'cam').first,
                                        :source_type => 'cell line')

          k = Karyotypes.find(kid)
          k.cell_line_id = cl.id
          k.save

        rescue Cytogenetics::StructureError => gse
          log.error( "#{gse.message}: #{file}")
        end
      end
    end
  end
end

def ncbi_skyfish(dir, log)
  esidir = "#{dir}/ESI/karyotype"
  Dir.foreach(esidir) do |entry|
    file = "#{esidir}/#{entry}"
    next if entry.start_with?(".")
    next if File.directory?(file)

    File.open("#{esidir}/#{entry}", 'r').each_with_index do |line, i|
      next if i.eql? 0
      line.chomp!

      (kcase, diag, stage, karyotypes) = line.split("\t")

      source_type = "patient"
      if entry.match("^NCI60")
        source_type = "cell line"
        cl = CellLine.where(:cell_line => kcase).first
      end

      next if kcase.match(/mouse/)
      log.info "Reading #{file} karyotype #{i}"
      karyotypes.split(/\//).each do |karyotype|
        begin
          kid = create_karyotype_record(:karyotype => karyotype, :cancer => cancer_name(diag),
                                        :source => KaryotypeSource.where("source_short = ?", 'ncbi').first,
                                        :source_type => source_type)
          unless cl.nil?
            k = Karyotypes.find(kid)
            k.cell_line_id = cl.cell_line_id
            k.save
          end
        rescue Cytogenetics::StructureError => gse
          log.error("#{gse.message}: NCBI karyotype #{entry} line #{i}")
          #rescue => error
          #  log.error("Failed to parse karyotype from Mitelman line #{i}: #{error.message}")
          #  log.error(error.backtrace)
          #  puts error.backtrace
        end
      end
    end
  end
end

def nci_fcrf(dir, log)
  crfdir = "#{dir}/ncifcrf"

  Dir.foreach(crfdir) do |tissuedir|
    next if tissuedir.start_with?(".")
    next unless File.directory? "#{crfdir}/#{tissuedir}"

    Dir.foreach("#{crfdir}/#{tissuedir}") do |entry|
      next if entry.start_with?(".")
      next if entry.eql? "url.txt"
      file = "#{crfdir}/#{tissuedir}/#{entry}"


      cl = CellLine.where(:cell_line => entry.sub(/\..*./, "")).first
      if cl.nil?
        cl = CellLine.create(:cell_line => entry.sub(/\..*./, ""))
      end

      log.info "Reading #{file}"
      karyotype = File.readlines(file).map! { |e| e.chomp! }
      karyotype = karyotype.join("")

      begin
        kid = create_karyotype_record(:karyotype => karyotype, :cancer => tissuedir,
                                      :source => KaryotypeSource.where("source_short = ?", 'ncifnl').first,
                                      :source_type => 'cell line')

        k = Karyotypes.find(kid)
        k.cell_line_id = cl.cell_line_id
        k.save

      rescue Cytogenetics::StructureError => gse
        log.error "#{gse.message}: #{file}"
      end
    end
  end
end


dir = "#{Dir.home}/Data/sky-cgh"
time = Time.new
date = time.strftime("%d%m%Y")

FileUtils.mkpath("#{dir}/logs/#{date}") unless File.exists? "#{dir}/logs/#{date}"

log = Logger.new("#{dir}/logs/#{date}/karyotype-resource.log")
#log.datetime_format = "%M"
log.level = Logger::INFO
Cytogenetics.logger = log


mitelman(dir, log)
ncbi_skyfish(dir, log)
cambridge(dir, log)
nci_fcrf(dir, log)
