class Breakpoints < ActiveRecord::Base
  set_table_name 'breakpoints'
  attr_accessible :breakpoint

  def Breakpoints.get_breaktpoints_by_karyotype(opts)
    karyotype_id = opts[:id]
    cancer = opts[:shortnames]

    breakpoints = find(:all) # TODO by id or cancer names
  end

  def Breakpoints.add_breakpoints(breakpoint, karyotype_id)
    Breakpoints.create(:breakpoint => breakpoint)
    ## TODO add to the reference table for breakpoint/karyotype
  end

end
