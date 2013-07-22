require 'active_record'
require 'rubygems'
require 'fileutils'
require 'cytogenetics'
require 'simple_matrix'
require 'logger'

require 'yaml'

#require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

ActiveRecord::Base.establish_connection(:adapter => 'mysql2',
                                        :database => 'karyotypes',
                                        :hostname => 'localhost',
                                        :username => 'root',
                                        :password => '',
                                        :socket => '/tmp/mysql.sock')

Dir.glob("../app/models/*.rb").each do |r|
  require r
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

def write_ploidy(ktids, filehandle)
  puts "Writing #{filehandle.path}"

  ch = {}; kts = {}
  Karyotype.where("id IN (#{ktids.join(',')})").find_in_batches do |batch|
    batch.each do |kt|
      puts "Karyotype #{kt.id}"
      kt.aberrations.each do |a|
        if a.aberration_class.match(/gain|loss/)
          key = a.aberration
          ch[key] = {:gain => 0, :loss => 0, :obj => a} unless ch.has_key? key
          ch[key][a.aberration_class.to_sym] += 1

          (kts[key] ||= []) << kt.id
        end
      end
    end
  end

  kts.each_pair { |k, l| l.uniq! }

  ch.each_pair do |chr, stats|
    kts[chr].uniq!
    filehandle.write [chr, stats[:gain], stats[:loss], kts[chr].length].join("\t") + "\n"
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

def write_breakpoints(abrids, ktids, filehandle)
  break_classes = ['trans', 'der', 'del', 'inv', 'dup']
  recombine_classes = ['trans', 'der', 'add', 'ins', 'dup']

  bph = {}; bpkt = []
  Karyotype.where("id IN (#{ktids.join(',')})").find_in_batches do |batch|
    batch.each do |kt|

      puts "Karyotype #{kt.id}"

      kt.aberrations.each do |abr|
        #bps = Breakpoint.joins(:aberrations).where("#{Aberration.table_name}.id = #{abr.id}")
        abr.breakpoints.each do |bp|
          bph[bp.breakpoint] = {:obj => bp, :kts => 0, :abrs => 0, :breaks => 0, :recomb => 0} unless bph.has_key? bp.breakpoint

          bpkt << bp.breakpoint

          bph[bp.breakpoint][:abrs] += 1
          bph[bp.breakpoint][:breaks] += 1 if break_classes.index(abr.aberration_class)
          bph[bp.breakpoint][:recomb] += 1 if recombine_classes.index(abr.aberration_class)
        end
      end
      bpkt.uniq!
      bpkt.each { |b| bph[b][:kts] += 1 }
    end
  end

  bph.each_pair do |bp, stats|
    warn "Missing information for #{bp}: " + YAML::dump(stats) if stats[:obj].nil?
    location = stats[:obj].position
    unless location.nil?
      filehandle.write [stats[:obj].chromosome, stats[:obj].band, location.start, location.end, stats[:abrs], stats[:breaks], stats[:recomb], stats[:kts]].join("\t") + "\n"
      filehandle.flush
    end
  end
  filehandle.close
end

query = 2
unless ARGV.length < 1
  query = ARGV[0].to_i
#else
#  puts "Require one of the following: 1 (all bps); 2 (ploidy); 3 (aberration); 4 (bps per cancer)"
#  exit
end

time = Time.new
date = time.strftime("%d%m%Y")

outdir = "#{Dir.home}/Data/sky-cgh/output/#{date}"

FileUtils.rm("#{Dir.home}/Data/sky-cgh/output/current") if File.exists?("#{Dir.home}/Data/sky-cgh/output/current")
FileUtils.symlink(outdir, "#{Dir.home}/Data/sky-cgh/output/current")

FileUtils.mkpath(outdir) unless File.exists? outdir


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
  cols = ['chr', 'band', 'start', 'end', 'total.breaks', 'total.recombination', 'total.aberrations', 'total.karyotypes']

  puts "Non leukemia aberrations: #{nonleuk_abr_ids.length}"
  write_breakpoints(nonleuk_abr_ids, nonleuk_kt_ids, get_filehandle("#{outdir}/noleuk-breakpoints.txt", cols))

  puts "Leukemia aberrations: #{leuk_abr_ids.length}"
  write_breakpoints(leuk_abr_ids, leukemia_karyotype_ids, get_filehandle("#{outdir}/leuk-breakpoints.txt", cols))
end

### -- Ploidy -- #
if (query.eql? 2)
  cols = ['chromosome', 'gain', 'loss', 'karyotypes']
  write_ploidy(nonleuk_kt_ids, get_filehandle("#{outdir}/noleuk-ploidy.txt", cols))
  write_ploidy(leukemia_karyotype_ids, get_filehandle("#{outdir}/leuk-ploidy.txt", cols))
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


if (query.eql? 5)
  classes = Aberration.find_by_sql("SELECT DISTINCT aberration_class FROM aberrations").map { |a| a.aberration_class }

  matrix = SimpleMatrix.new
  matrix.colnames = classes

  Breakpoint.all.each do |bp|

    bps = {}
    classes.each { |c| bps[c] = 0 }
    bp.aberrations.each do |abr|
      bps[abr.aberration_class] += 1
    end

    matrix.add_row(bp.breakpoint, classes.map { |c| bps[c] })
  end

  matrix.write("#{outdir}/bp-classes.txt")
end

if (query.eql? 6)
  kt_bp_count = []
  chr_kt_count = []
  ploidy_count = []
  Karyotype.find_in_batches do |batch|
    batch.each do |kt|
      puts "Karyotype #{kt.id}"
      chrs = {}
      bps = kt.breakpoints
      bps.each do |bp|
        chrs[bp.chromosome] = 0 unless chrs.has_key? bp.chromosome
        chrs[bp.chromosome] += 1
      end
      bps.uniq!
      kt_bp_count << bps.length
      chr_kt_count << chrs.keys.length

      pdy = 0
      kt.aberrations.each do |abr|
        pdy += 1 if abr.aberration_class.match(/gain|loss/)
      end
      ploidy_count << pdy
    end
  end

  count = {}
  kt_bp_count.each { |k| count[k] = 0 unless count.has_key? k; count[k] += 1 }
  File.open("#{outdir}/bp_per_kt.txt", 'w') do |f|
    f.write("# Total breakpoints per karyotype \n")
    count.each_pair do |k, v|
      f.write([k, v].join("\t") + "\n")
    end
  end

  count = {}
  chr_kt_count.each { |k| count[k] = 0 unless count.has_key? k; count[k] += 1 }
  File.open("#{outdir}/chr_per_kt.txt", 'w') do |f|
    f.write("# Total chromosomes involve in breakpoints per karyotype\n")
    count.each_pair do |k, v|
      f.write([k, v].join("\t") + "\n")
    end
  end

  count = {}
  ploidy_count.each { |k| count[k] = 0 unless count.has_key? k; count[k] += 1 }
  File.open("#{outdir}/ploidy_per_kt.txt", 'w') do |f|
    f.write("# Total aneuploidy per karyotype")
    count.each_pair do |k, v|
      f.write([k, v].join("\t") + "\n")
    end
  end

end

if query.eql? 7
  puts "Getting counts..."
  File.open("#{outdir}/abr_per_kt.txt", 'w') { |f|
    f.write ['karyotype', 'aneuploidy.count', 'aberrations.count'].join("\t") + "\n"
    Karyotype.find_in_batches do |batch|
      puts batch.length
      batch.each do |kt|
        pdy = kt.aberrations.select { |abr| abr.aberration_class.match(/gain|loss/) }
        abrs = kt.aberrations.reject { |abr| abr.aberration_class.match(/gain|loss/) }
        f.write [kt.id, pdy.length, abrs.length].join("\t") + "\n"
      end
    end
  }
end
