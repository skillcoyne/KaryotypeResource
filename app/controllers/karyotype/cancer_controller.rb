class Karyotype::CancerController < ApplicationController
  add_breadcrumb 'Cancers', 'cancer'

  def index
    @cancers = Cancer.order("name")
  end

  def show
    name = params[:id]
    add_breadcrumb name, ''
    @cancer = Cancer.where("name" => name).includes(:karyotypes => [:karyotype_source]).order("karyotype_source.source").first
    @karyotype_by_source = {}
    @cancer.karyotypes.each do |k|
      (@karyotype_by_source[k.karyotype_source] ||= []) << k
    end
    @karyotype_by_source
    @cancer
  end
end
