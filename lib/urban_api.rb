require 'nokogiri'
require 'faraday'

class UrbanAPI
  VERSION = "0.1.0"

  class Definition < Struct.new(:definition, :example)
  end

  class << self
    attr_accessor :urbandictionary_url
  end
  self.urbandictionary_url = "http://www.urbandictionary.com"

  def self.define(*args)
    new.define(*args)
  end

  def initialize(connection = Faraday.default_connection)
    @conn = connection
    @conn.url_prefix = self.class.urbandictionary_url
  end

  # http://www.urbandictionary.com/define.php?term=git&page=1
  def define(word, options = {})
    resp = @conn.get('define.php') do |req|
      req.params['term'] = word
      req.params['page'] = options[:page].to_i if options.key?(:page)
    end
    definitions_from_html Nokogiri::HTML(resp.body)
  end

  def definitions_from_html(doc)
    defs = []
    (doc / "table#entries tr").each do |row|
      if defn = (row / 'div.definition').first
        ex = (row / 'div.example').first
        defs << Definition.new(defn.inner_html, ex ? ex.inner_html : nil)
      end
    end
    defs
  end
end
