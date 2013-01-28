require 'yaml'

class Karyotype::DataSourceController < ApplicationController

  def show
    @karyotype = Karyotype.where('id' => params[:id]).includes(:cell_line, :karyotype_source, :cancers).first
    add_breadcrumb "Karyotype #{@karyotype.karyotype[0,10]}...", ''
  end
end
