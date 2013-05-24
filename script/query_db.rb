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

def write_bp_cnc(cancers, filehandle)
  puts "Writing #{filehandle.path}"
  cancers.each do |c|
    puts "Reading #{c.name}..."
    bps = []
    bps << c.karyotypes.map { |k| k.breakpoints }
    bps.flatten!

    ## NOTE For now output major bands only
    bps.each do |bp|
      filehandle.write [bp.chromosome, bp.major_breakpoint, bp.position(:major).first, bp.position(:major).last, c.name].join("\t") + "\n"
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

    filehandle.write [a.aberration_class, a.aberration, a.breakpoints.length, a.karyotypes.length].join("\t") + "\n"
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
  puts "Writing #{filehandle.path}"
  puts bps.length
  bps.each do |bp|
    bp.karyotypes.uniq! { |k| k.id }

    cnc = Cancer.joins(:karyotypes).where(:karyotypes => {:id => bp.karyotypes.map { |k| k.id }})
    cnc.uniq! { |c| c.id }

    patients = bp.karyotypes.select { |k| k.source_type.eql? 'patient' }.length
    cell_lines = bp.karyotypes.select { |k| k.source_type.eql? 'cell line' }.length

    filehandle.write [bp.chromosome, bp.band, bp.position, patients, cell_lines, cnc.length].join("\t") + "\n"
    filehandle.flush
  end
  filehandle.close
end

time = Time.new
date = time.strftime("%d%m%Y")

## Pull down breakpoints by cancer, with locations
outdir = "#{Dir.home}/Data/sky-cgh/output/#{date}"

FileUtils.rm_f("#{Dir.home}/Data/sky-cgh/output/current") if File.exists?("#{Dir.home}/Data/sky-cgh/output/current")
FileUtils.symlink(outdir, "#{Dir.home}/Data/sky-cgh/output/current")

FileUtils.mkpath(outdir) unless File.exists? outdir

# -- Cancer breakpoints -- #
cols = ["chr", "breakpoint", "start", "end", "cancer"]
cancers = Cancer.joins(:karyotypes => [:breakpoints]).where(:karyotypes => {:source_type => 'patient'})
write_bp_cnc(cancers, get_filehandle("#{outdir}/pt-breakpoints.txt", cols))

cancers = Cancer.joins(:karyotypes => [:breakpoints]).where(:karyotypes => {:source_type => 'cell line'})
write_bp_cnc(cancers, get_filehandle("#{outdir}/cl-breakpoints.txt", cols))

# -- Breakpoints -- #
write_breakpoints(Breakpoint.all, get_filehandle("#{outdir}/breakpoints.txt", ['chr', 'band', 'start', 'end', 'patients', 'cell.lines', 'cancers']))

# -- All known aberrations that have breakpoints -- #
write_abr_file(Aberration.where("aberration_class != ?", 'unk'), get_filehandle("#{outdir}/aberrations.txt", ['class', 'aberration', 'breakpoints', 'karyotypes']))

# -- Ploidy -- #
write_ploidy(Aberration.where("aberration_class IN (?,?)", 'gain', 'loss'), get_filehandle("#{outdir}/ploidy.txt", ['class', 'chromosome', 'karyotypes']))


