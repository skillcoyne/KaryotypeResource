require 'active_record'
require 'rubygems'
require 'fileutils'
require 'cytogenetics'
require 'logger'

require 'yaml'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

def get_bp_filehandle(filename, cols = ["Chr", "Breakpoint", "Start", "End", "Cancer", "Source"])
  f = File.open(filename, 'w')
  f.write(cols.join("\t") + "\n")
  return f
end

def write_breakpoint_file(cancers, filehandle)
  puts "Writing #{filehandle.path}"
  cancers.each do |c|
    puts "Reading #{c.name}..."
    bps = []
    bps << c.karyotypes.map { |k| k.breakpoints }
    bps.flatten!

    ## NOTE For now output major bands only
    bps.each { |bp|
      str = "#{bp.chromosome}\t#{bp.major_breakpoint}\t#{bp.position(:major).first}\t#{bp.position(:major).last}\t#{c.name}\n"
      filehandle.write str
    }
  end
  filehandle.close
end


time = Time.new
date = time.strftime("%d%m%Y")

## Pull down breakpoints by cancer, with locations
outdir = "#{Dir.home}/Data/sky-cgh/output/#{date}"

FileUtils.rm_f("#{Dir.home}/Data/sky-cgh/output/current") if File.exists?("#{Dir.home}/Data/sky-cgh/output/current")
FileUtils.symlink(outdir, "#{Dir.home}/Data/sky-cgh/output/current")

FileUtils.mkpath(outdir) unless File.exists?outdir

cancers = Cancer.joins(:karyotypes => [:breakpoints]).where(:karyotypes => {:source_type => 'patient'})
write_breakpoint_file(cancers, get_bp_filehandle("#{outdir}/pt-breakpoints.txt"))

cancers = Cancer.joins(:karyotypes => [:breakpoints]).where(:karyotypes => {:source_type => 'cell line'})
write_breakpoint_file(cancers, get_bp_filehandle("#{outdir}/cl-breakpoints.txt"))
