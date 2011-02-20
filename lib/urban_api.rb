require 'nokogiri'
require 'faraday'

class UrbanAPI
  VERSION = "0.2.0"

  class Definition < Struct.new(:definition, :example)
    def self.create(def_node, example_node)
      new(extract_from(def_node), extract_from(example_node))
    end

    def self.extract_from(node)
      if node
        node.inner_html
      end
    end
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
    definitions_from_html resp.body
  end

  def definitions_from_html(html)
    defs = []
    (Nokogiri::HTML(html) / "table#entries tr").each do |row|
      if defn = (row / 'div.definition').first
        defs << Definition.create(defn, (row / 'div.example').first)
      end
    end
    defs
  end
end
