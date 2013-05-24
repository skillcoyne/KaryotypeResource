require 'active_record'
require 'rubygems'
require 'fileutils'
require 'cytogenetics'
require 'logger'

require 'yaml'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")


def create_karyotype_record(args)
  cancer = args[:cancer]
  args.delete(:cancer)

  kt = Cytogenetics.karyotype(args[:karyotype])
  abr_bp_hash = kt.associate_bp_to_abr

  ktmodel = Karyotype.create(args)
  if ktmodel
    KaryotypeSource.increment_counter(:karyotype_count, args[:karyotype_source_id])

    ktmodel.cancers << Cancer.find_or_create_by_name(cancer)

    kt.aberrations.each_pair do |ab_class, aberrations|
      aberrations.each do |abr|
        abrmodel = Aberration.find_or_create_by_aberration_and_aberration_class(abr, ab_class)
        ktmodel.aberrations << abrmodel

        if abr_bp_hash.has_key? abr
          abr_bp_hash[abr].each do |bp|
            bpmodel = Breakpoint.find_or_create_by_breakpoint(bp)
            ktmodel.breakpoints << bpmodel

            abrmodel.breakpoints << bpmodel
          end
        end
      end
    end
    ktmodel.save
  else
    puts "**** Failed to create karyotype record for #{args.inspect}"
  end

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
  time_accessed = File.ctime("#{dir}/mitelman/mm-kary_cleaned.txt").strftime("%Y-%m-%d")

  ks = KaryotypeSource.where(:source_short => 'mitelman').first

  File.open("#{dir}/mitelman/mm-kary_cleaned.txt", 'r').each_with_index do |line, i|
    line.chomp!
    next if line.start_with? "#"
    log.info "Reading  Mitelman karyotype # #{i}"
    #log.info("Reading  Mitelman karyotype # #{i}: #{dir}/mm-karyotypes.txt")
    (karyotype, morph, shortmorph, refno, caseno) = line.split(/\t/)

    begin
      create_karyotype_record(:karyotype => karyotype, :cancer => cancer_name(morph),
                              :karyotype_source_id => ks.id, :source_type => 'patient',
                              :description => "#{morph}, Reference: #{refno}, Case: #{caseno}")
    rescue Cytogenetics::StructureError => gse
      log.error("#{gse.message}: Mitelman line #{i}")
    end
  end
end

def cambridge(dir, log)
  camdir = "#{dir}/path.cam.ac.uk"
  time_accessed = File.ctime("#{camdir}").strftime("%Y-%m-%d")

  ks = KaryotypeSource.where(:source_short => 'cam').first

  Dir.foreach(camdir) do |tissuedir|
    next if tissuedir.start_with?(".")
    next unless File.directory? "#{camdir}/#{tissuedir}"

    Dir.foreach("#{camdir}/#{tissuedir}") do |entry|
      next if entry.start_with?(".")
      next if entry.eql? "url.txt"
      file = "#{camdir}/#{tissuedir}/#{entry}"

      cl = CellLine.find_or_create_by_name(entry.sub(/\..*./, ""))

      log.info "Reading #{file}..."
      File.open(file, 'r').each_line do |karyotype|
        karyotype.chomp!
        next if karyotype.length <= 1

        begin
          create_karyotype_record(:karyotype => karyotype, :cancer => tissuedir,
                                  :karyotype_source_id => ks.id, :cell_line_id => cl.id,
                                  :source_type => 'cell line')
        rescue Cytogenetics::StructureError => gse
          log.error("#{gse.message}: #{file}")
        end
      end
    end
  end
end

def ncbi_skyfish(dir, log)
  esidir = "#{dir}/ESI/karyotype"
  time_accessed = File.ctime("#{esidir}").strftime("%Y-%m-%d")

  ks = KaryotypeSource.where(:source_short => 'ncbi').first

  Dir.foreach(esidir) do |entry|
    file = "#{esidir}/#{entry}"
    next if entry.start_with?(".")
    next if File.directory?(file)

    File.open(file, 'r').each_with_index do |line, i|
      next if i.eql? 0
      log.info "Reading #{file} karyotype #{i}"
      line.strip!

      line.gsub!(/\r|\n/, "")
      (kcase, diag, stage, karyotypes) = line.split("\t")
      next if kcase.match(/mouse/)

      source_type = "patient"
      if entry.match("^NCI60")
        source_type = "cell line"
        cl_name = kcase[0..kcase.index("(")-1]
        cl_name.strip!
        cl = CellLine.where(:name => [cl_name, cl_name.sub("-", "")]).first
      end

      karyotypes.split(/\//).each do |karyotype|
        puts karyotype
        begin
          kid = create_karyotype_record(:karyotype => karyotype, :cancer => cancer_name(diag), :description => "#{kcase}: #{stage}",
                                        :karyotype_source_id => ks.id, :source_type => source_type)
          Karyotype.find(kid).update_attribute("cell_line_id", cl.id) unless cl.nil?
        rescue Cytogenetics::StructureError => gse
          log.error("#{gse.message}: NCBI karyotype #{entry} line #{i}")
        end
      end
    end
  end

end

def nci_fcrf(dir, log)
  crfdir = "#{dir}/ncifcrf"
  time_accessed = File.ctime("#{crfdir}").strftime("%Y-%m-%d")

  ks = KaryotypeSource.where(:source_short => 'ncifnl').first

  Dir.foreach(crfdir) do |tissuedir|
    next if tissuedir.start_with?(".")
    next unless File.directory? "#{crfdir}/#{tissuedir}"

    Dir.foreach("#{crfdir}/#{tissuedir}") do |entry|
      next if entry.start_with?(".")
      next if entry.eql? "url.txt"
      file = "#{crfdir}/#{tissuedir}/#{entry}"


      cl = CellLine.find_or_create_by_name(entry.sub(/\..*./, ""))

      log.info "Reading #{file}"
      karyotype = File.readlines(file).map! { |e| e.chomp! }
      karyotype = karyotype.join("")

      begin
        create_karyotype_record(:karyotype => karyotype, :cancer => tissuedir, :cell_line_id => cl.id,
                                :karyotype_source_id => ks.id, :cell_line_id => cl.id,
                                :source_type => 'cell line')
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
log.level = Logger::INFO
Cytogenetics.logger = log

parse_log = Logger.new(STDOUT)
parse_log.level = Logger::INFO


mitelman(dir, parse_log)
ncbi_skyfish(dir, parse_log)
cambridge(dir, parse_log)
nci_fcrf(dir, parse_log)
