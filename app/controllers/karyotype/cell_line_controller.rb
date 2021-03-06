require 'yaml'

class Karyotype::CellLineController < ApplicationController
  add_breadcrumb 'Cell Lines', 'karyotype/cell_line'

  def show
    cl = CellLine.where(:name => params[:id]).includes(:karyotype => [:karyotype_source]).first
    add_breadcrumb cl.name, ''
    @cell_line = cl
  end

  def index
    @cell_lines = CellLine.all
    @cell_lines.sort_by!{|c| c.name}
  end
end
