require 'active_record'
require 'rubygems'
require 'fileutils'
require 'cytogenetics'
require 'logger'

require 'yaml'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

def get_filehandle(filename, cols)
  f = File.open(filename, 'w')
  f.write(cols.join("\t") + "\n")
  return f
end

def write_bp_cnc(bps, filehandle)
  puts "Writing #{filehandle.path}"

  bps.each do |bp|

    chr_location = bp.position(:major)
    unless chr_location.nil?
      patients = bp.karyotypes.select { |k| k.source_type.eql? 'patient' }.length
      cell_lines = bp.karyotypes.select { |k| k.source_type.eql? 'cell line' }.length

      filehandle.write [bp.chromosome, chr_location.band, chr_location.start, chr_location.end, patients, cell_lines, bp.karyotypes.length].join("\t") + "\n"
      filehandle.flush
    end

  end
  filehandle.close
end

def write_abr_file(abrs, filehandle)
  puts "Writing #{filehandle.path}"
  puts abrs.length
  abrs.each_with_index do |a, i|
    a.breakpoints.uniq! { |bp| bp.id }
    a.karyotypes.uniq! { |k| k.id }

    leukemia_count = 0
    cnc = Cancer.joins(:karyotypes).where(:karyotypes => {:id => a.karyotypes.map { |k| k.id }})

    cnc.each { |c| leukemia_count += 1 if $LEUKEMIAS.index(c.name) }


    filehandle.write [a.aberration_class, a.aberration, a.breakpoints.length, a.karyotypes.length, leukemia_count].join("\t") + "\n"
    filehandle.flush if i%10 == 0
  end
  filehandle.close
end

def write_ploidy(abrs, filehandle)
  puts "Writing #{filehandle.path}"
  puts abrs.length
  abrs.each do |a|
    a.karyotypes.uniq! { |k| k.id }
    filehandle.write [a.aberration_class, a.aberration, a.karyotypes.length].join("\t") + "\n"
    filehandle.flush
  end
  filehandle.close
end

def write_breakpoints(bps, filehandle)
  leukemia_ids = Cancer.where(:name => $LEUKEMIAS)
  leukemia_ids = leukemia_ids.map { |leu| leu.id }

  break_classes = ['trans', 'der', 'del', 'inv', 'dup', 'add']
  recombine_classes = ['trans', 'der', 'add', 'inv', 'ins', 'dup']
  #ab_objs = Cytogenetics::Aberration.aberration_objs

  puts "Writing #{filehandle.path}"
  puts bps.length
  bps.each do |bp|
    bp.karyotypes.uniq! { |k| k.id }

    # counts leukemia samples
    leuk_count = 0
    bp.karyotypes.each { |k|
      k.cancers.each { |c| leuk_count += 1 if leukemia_ids.index(c.id) }
    }

    patients = bp.karyotypes.select { |k| k.source_type.eql? 'patient' }.length
    cell_lines = bp.karyotypes.select { |k| k.source_type.eql? 'cell line' }.length

    breaks = 0; recombinations = 0
    bp.aberrations.each do |a|
      # Not sure it's at all useful to do this
      #breaks = ab_objs[a.aberration_class.to_sym].new(a.aberration,false)

      # Basically if a breakpoint shows up in one of the listed aberrations it's counted as either (or both) a breakage or a recombination
      # This does completely ignore where it shows up in the aberration.  For instance t(11;17)(p15;q21) 11p15 will be both a break and a recombination site.
      breaks += 1 if break_classes.index(a.aberration_class)
      recombinations += 1 if recombine_classes.index(a.aberration_class)
    end

    chr_location = bp.position
    unless chr_location.nil?
      filehandle.write [bp.chromosome, bp.band, chr_location.start, chr_location.end, breaks, recombinations, bp.aberrations.length, patients, cell_lines, bp.karyotypes.length, leuk_count].join("\t") + "\n"
      filehandle.flush
    end
  end
  filehandle.close
end



time = Time.new
date = time.strftime("%d%m%Y")

outdir = "#{Dir.home}/Data/sky-cgh/output/#{date}"

FileUtils.rm_f("#{Dir.home}/Data/sky-cgh/output/current") if File.exists?("#{Dir.home}/Data/sky-cgh/output/current")
FileUtils.symlink(outdir, "#{Dir.home}/Data/sky-cgh/output/current")

FileUtils.mkpath(outdir) unless File.exists? outdir

$LEUKEMIAS = ['Acute myeloid leukemia', 'Acute lymphoblastic leukemia', "Non-hodgkin's lymphoma", 'Chronic myelogenous leukemia', 'Chronic lymphocytic leukemia']

### -- Breakpoints -- #
write_breakpoints(Breakpoint.all, get_filehandle("#{outdir}/breakpoints.txt", ['chr', 'band', 'start', 'end', 'total.breaks', 'total.recombination', 'total.aberrations', 'patients', 'cell.lines', 'total.karyotypes', 'leukemia.karyotypes']))

### -- Ploidy -- #
#write_ploidy(Aberration.where("aberration_class IN (?,?)", 'gain', 'loss'), get_filehandle("#{outdir}/ploidy.txt", ['class', 'chromosome', 'karyotypes']))

### -- All known aberrations that have breakpoints -- #
#write_abr_file(Aberration.where("aberration_class != ?", 'unk'), get_filehandle("#{outdir}/aberrations.txt", ['class', 'aberration', 'breakpoints', 'karyotypes', 'leukemias']))

# -- Cancer breakpoints -- #
#cncdir = "#{outdir}/cancer_bps"
#FileUtils.rm_rf(cncdir) if File.exists?cncdir
#FileUtils.mkpath(cncdir)
#
#cancers = Cancer.all
#cancers.each do |cnc|
#  puts "#{cnc.name}: #{cnc.karyotypes.length}"
#  bps = []
#  cnc.karyotypes.each do |k|
#    bps << k.breakpoints
#  end
#  bps.flatten!
#  bps.uniq!{|bp| bp.id}
#
#  filename = cnc.name.gsub(/\//, "_")
#  filename.gsub!(/\s/, "_")
#  write_breakpoints(bps,get_filehandle("#{cncdir}/#{filename}.txt", ['chr', 'band', 'start', 'end', 'patients', 'cell.lines', 'total.samples']))
#end
#
#
