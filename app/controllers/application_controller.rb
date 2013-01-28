require 'yaml'

class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'main'

  def index

  end

  protected
  def add_breadcrumb name, url = ''
    @breadcrumbs ||= []
    url = eval(url) if url =~ /_path|_url|@/
    logger.info( YAML::dump(@breadcrumbs) )
    @breadcrumbs << [name, url]
  end

  def self.add_breadcrumb name, url, options = {}
    before_filter options do |controller|
      controller.send(:add_breadcrumb, name, url)
    end
  end

  protected
  def get_statistics
    @count = KaryotypeSource.sum("karyotype_count")
    @sources = KaryotypeSource.all
  end

  def self.get_statistics
    before_filter do |controller|
      controller.send(:get_statistics)
    end
  end

  get_statistics

end
