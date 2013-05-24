require 'yaml'

class Breakpoint < ActiveRecord::Base
  self.table_name = 'breakpoints'

  has_and_belongs_to_many :karyotypes
  has_and_belongs_to_many :aberrations

  attr_reader :startpos, :endpos

  def chromosome
    m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+.*)/)
    return m.captures.first
  end

  def major_breakpoint
    return "#{self.chromosome}#{self.band(:major)}"
  end

  def band(*args)
    m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+.*)/)
    if args[0].eql? 'major'.to_sym
      m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+)/)
    end
    return m.captures.last
  end

  def position(*args)
    cb = ChromosomeBands.find_by_chromosome_and_band(self.chromosome, "#{self.band(*args)}")
    return cb
    #return [cb.start, cb.end]
  end

end
