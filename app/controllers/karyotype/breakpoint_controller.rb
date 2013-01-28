require 'yaml'

class Karyotype::BreakpointController < ApplicationController

  add_breadcrumb 'Breakpoints', 'karyotype/breakpoint'

  def index
      @breakpoints = Breakpoint.includes(:karyotypes)
      @breakpoints.sort_by! { |bp| bp.karyotypes.length }
      @breakpoints
  end

  def show
    breakpoint = params[:id]
    add_breadcrumb breakpoint, ''
    @breakpoints = Breakpoint.where('breakpoint' => breakpoint).includes(:karyotypes => [:karyotype_source, :cell_line])
  end

end
