require 'yaml'

class Breakpoint < ActiveRecord::Base
  self.table_name = 'breakpoints'

  has_and_belongs_to_many :karyotypes

  def chromosome
    m = self.breakpoint.match(/(\d+|X|Y)([q|p]\d+.*)/)
    return m.captures.first
  end


end
