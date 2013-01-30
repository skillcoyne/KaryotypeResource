require 'yaml'

class Karyotype::DataSourceController < ApplicationController

  def show
    logger.info(params.inspect)
    if params[:id].match(/\d+/)

      @karyotype = Karyotype.where(:id => params[:id]).includes(:cell_line, :karyotype_source, :cancers).first
      add_breadcrumb "Karyotype #{@karyotype.karyotype[0,10]}...", ''

    elsif params[:id].match(/^[a-z]+$/)

      @source = KaryotypeSource.where('source_short' => params[:id]).includes(:karyotypes => [:cell_line, :cancers]).first

      @cell_lines = []; @cancers = []
      @source.karyotypes.each do |k|
        @cell_lines << k.cell_line if k.cell_line
        @cancers << k.cancers if k.cancers
      end
      @cancers.flatten!
      @cancers.uniq_by!{|c| c.name }
      @cancers.sort_by!{|c| c.name }
      @cell_lines.uniq_by!{|cl| cl.name }

      add_breadcrumb @source.source, ''
    end

  end
end
