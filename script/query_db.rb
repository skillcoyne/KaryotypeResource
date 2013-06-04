require 'active_record'
require 'rubygems'
require 'fileutils'
require 'cytogenetics'
require 'logger'

require 'yaml'

#require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

ActiveRecord::Base.establish_connection(:adapter => 'mysql2',
                                        :database => 'cancer_karyotypes',
                                        :hostname => 'localhost',
                                        :username => 'root',
                                        :password => '',
                                        :socket => '/tmp/mysql.sock')

Dir.glob("../app/models/*.rb").each do |r|
  require r
end


class BPCountHash
  def initialize
    @obj = {}
    @count = {}
    @abrs = {}
    @breaks = {}
    @recombs = {}
    @kts = {}
  end

  def add_abr(bp, c = 1)
    bp(bp)
    @abrs[bp] += c
  end

  def add_bk(bp, c = 1)
    bp(bp)
    @breaks[bp] += c
  end

  def add_rc(bp, c = 1)
    bp(bp)
    @recombs[bp] += c
  end

  def add_kt(bp, c = 1)
    bp(bp)
    @kts[bp] += c
  end

  def keys
    @obj.keys
  end

  def counts(bp)
    return {:obj => @obj[bp], :count => @count[bp], :abr => @abrs[bp], :breaks => @breaks[bp], :recombs => @recombs[bp], :kts => @kts[bp]}
  end

  def add_bp(bpobj)
    unless @obj.has_key? bpobj.breakpoint
      @obj[bpobj.breakpoint] = bpobj
      @count[bpobj.breakpoint] = 0
    end
    @count[bpobj.breakpoint] += 1
  end

  :private

  def bp(bp)
    @abrs[bp] = 0 unless @abrs.has_key? bp
    @breaks[bp] = 0 unless @breaks.has_key? bp
    @recombs[bp] = 0 unless @recombs.has_key? bp
    @kts[bp] = 0 unless @kts.has_key? bp
    @count[bp] = 0 unless @count.has_key? bp
  end

end

def get_filehandle(filename, cols)
  f = File.open(filename, 'w')
  f.write(cols.join("\t") + "\n")
  return f
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

def write_ploidy(abrs, ktids, filehandle)
  puts "Writing #{filehandle.path}"
  abrs.each do |a|
    a.karyotypes.delete_if { |k| ktids.index(k.id) }
    a.karyotypes.uniq! { |k| k.id }

    filehandle.write [a.aberration_class, a.aberration, a.karyotypes.length].join("\t") + "\n"
    filehandle.flush
  end
  filehandle.close
end

def write_cnc_breakpoints(bps, filehandle)
  break_classes = ['trans', 'der', 'del', 'inv', 'dup', 'add']
  recombine_classes = ['trans', 'der', 'add', 'inv', 'ins', 'dup']

  puts "Writing #{filehandle.path}"
  puts bps.length
  bps.each do |bp|
    bp.karyotypes.uniq! { |k| k.id }

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
      filehandle.write [bp.chromosome, bp.band, chr_location.start, chr_location.end, breaks, recombinations, bp.aberrations.length, patients, cell_lines, bp.karyotypes.length].join("\t") + "\n"
      filehandle.flush
    end
  end
  filehandle.close
end

def write_breakpoints(abrids, filehandle)
  break_classes = ['trans', 'der', 'del', 'inv', 'dup']
  recombine_classes = ['trans', 'der', 'add', 'ins', 'dup']

  ch = BPCountHash.new()

  Aberration.where("id IN (#{abrids.join(',')})").find_in_batches do |batch|
    batch.each do |abr|
      puts "((( Abr #{abr.id} )))"
      abr.breakpoints.each do |bp|
        ch.add_bp(bp)
        ch.add_abr(bp.breakpoint)
        ch.add_bk(bp.breakpoint) if break_classes.index(abr.aberration_class)
        ch.add_rc(bp.breakpoint) if recombine_classes.index(abr.aberration_class)
        ch.add_kt(bp.breakpoint, abr.karyotypes.length)
        ch.add_bk(bp.breakpoint) if break_classes.index(abr.aberration_class)
        ch.add_rc(bp.breakpoint) if recombine_classes.index(abr.aberration_class)
      end
    end
    break
  end

  ch.keys.each do |bp|
    stats = ch.counts(bp)

    location = stats[:obj].position
    unless location.nil?
      filehandle.write [stats[:obj].chromosome, stats[:obj].band, location.start, location.end, stats[:count], stats[:breaks], stats[:recombs], stats[:kts]].join("\t") + "\n"
      filehandle.flush
    end
  end
  filehandle.close
end


query = 1
unless ARGV.length < 1
  query = ARGV[0].to_i
else
  puts "Require one of the following: 1 (all bps); 2 (ploidy); 3 (aberration); 4 (bps per cancer)"
  exit
end


time = Time.new
date = time.strftime("%d%m%Y")

outdir = "#{Dir.home}/Data/sky-cgh/output/#{date}"


#FileUtils.rm_f("#{Dir.home}/Data/sky-cgh/output/current") if File.exists?("#{Dir.home}/Data/sky-cgh/output/current")
#FileUtils.symlink(outdir, "#{Dir.home}/Data/sky-cgh/output/current")

#FileUtils.mkpath(outdir) unless File.exists? outdir

## These two account for about 34% of all karyotypes analyzed
$LEUKEMIAS = ['Acute myeloid leukemia', 'Acute lymphoblastic leukemia']

leukemia_karyotype_ids = Karyotype.joins(:cancers).where('cancer.name' => $LEUKEMIAS).pluck("#{Karyotype.table_name}.id")
nonleuk_kt_ids = Karyotype.where("id NOT IN (#{leukemia_karyotype_ids.join(',')})").uniq.pluck(:id)

nonleuk_abr_ids = Aberration.joins(:karyotypes).where("#{Karyotype.table_name}.id NOT IN (#{leukemia_karyotype_ids.join(',')})").uniq.pluck("#{Aberration.table_name}.id")
nonleuk_abr_ids.sort!

leuk_abr_ids = Aberration.joins(:karyotypes).where("#{Karyotype.table_name}.id IN (#{leukemia_karyotype_ids.join(',')})").uniq.pluck("#{Aberration.table_name}.id")
leuk_abr_ids.sort!


### -- Breakpoints, separated top leukemias and all other cancers -- #
if (query.eql? 1)
  cols =  ['chr', 'band', 'start', 'end', 'total.breaks', 'total.recombination', 'total.aberrations', 'total.karyotypes']
  puts "Non leukemia aberrations: #{nonleuk_abr_ids.length}"
  write_breakpoints(nonleuk_abr_ids, get_filehandle("#{outdir}/noleuk-breakpoints.txt", cols))

  puts "Leukemia aberrations: #{leuk_abr_ids.length}"
  write_breakpoints(leuk_abr_ids, get_filehandle("#{outdir}/leuk-breakpoints.txt", cols))
end

### -- Ploidy -- #
if (query.eql? 2)
  write_ploidy(Aberration.where("aberration_class IN ('gain','loss') AND id IN (#{nonleuk_abr_ids.join(',')})",),
               nonleuk_kt_ids,
               get_filehandle("#{outdir}/noleuk-ploidy.txt", ['class', 'chromosome', 'karyotypes']))
  write_ploidy(Aberration.where("aberration_class IN ('gain','loss') AND id IN (#{leuk_abr_ids.join(',')})",),
               leukemia_karyotype_ids,
               get_filehandle("#{outdir}/leuk-ploidy.txt", ['class', 'chromosome', 'karyotypes']))
end

### -- All known aberrations that have breakpoints -- #
if (query.eql? 3)
  write_abr_file(Aberration.where("aberration_class != 'unk' AND id IN (#{nonleuk_abr_ids.join(',')})"),
                 get_filehandle("#{outdir}/noleuk-aberrations.txt", ['class', 'aberration', 'breakpoints', 'karyotypes', 'leukemias']))
  write_abr_file(Aberration.where("aberration_class != 'unk' AND id IN (#{leuk_abr_ids.join(',')})"),
                 get_filehandle("#{outdir}/leuk-aberrations.txt", ['class', 'aberration', 'breakpoints', 'karyotypes', 'leukemias']))
end

# -- Cancer breakpoints -- #
if (query.eql? 4)
  puts "Querying cancer breakpoints"
  cncdir = "#{outdir}/cancer_bps"

  FileUtils.mkpath(cncdir) unless File.exists? cncdir

  cancers = Cancer.order("name")

  cancers.each do |cnc|
    puts "#{cnc.name}: #{cnc.karyotypes.length}"
    filename = cnc.name.gsub(/\//, "_")
    filename.gsub!(/\s/, "_")

    next if File.exists? "#{cncdir}/#{filename}.txt"
    bps = []
    cnc.karyotypes.each do |k|
      bps << k.breakpoints
    end
    bps.flatten!
    bps.uniq! { |bp| bp.id }

    write_cnc_breakpoints(bps,
                          get_filehandle("#{cncdir}/#{filename}.txt",
                                         ['chr', 'band', 'start', 'end', 'total.breaks', 'total.recombination', 'total.aberrations', 'patients', 'cell.lines', 'total.karyotypes', 'leukemia.karyotypes']))
  end
end


