require 'yaml'

class Breakpoint < ActiveRecord::Base
  self.table_name = 'breakpoints'

  has_and_belongs_to_many :karyotypes
  has_and_belongs_to_many :aberrations

  def chromosome
    m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+.*)/)
    return m.captures.first
  end

  def major_breakpoint
    return "#{self.chromosome}#{self.band(:major)}"
  end

  def band(*args)
    m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+.*)/)
    if args[0].eql?'major'.to_sym
      m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+)/)
    end
    return m.captures.last
  end

  def position(*args)
    unless ((@startpos and @endpos) and args.length.eql?0)
      cb = ChromosomeBands.where("chromosome = ? AND band LIKE ?", self.chromosome, "%#{self.band(*args)}%").order(:start)
      @startpos = cb.first.start
      @endpos = cb.last.end
    end
    return [@startpos, @endpos]
  end

end
