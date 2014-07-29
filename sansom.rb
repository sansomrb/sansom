#!/usr/bin/env ruby

require "rack"
require "tree" # rubytree

class Sansom
  class TreeContent
    attr_accessor :items, :map
    def initialize
      @items = []
      @map = {}
    end
  
    def []=(k,v)
      @items << v if k == :map
      @map[k] = v unless k == :map
    end
  
    def [](k)
      @items[k] if Numeric === k
      @map[k] unless Numeric === k
    end
  end
  
  InvalidRouteError = Class.new StandardError
  NoRoutesError = Class.new StandardError
  
  HTTP_VERBS = ["GET","HEAD","POST","PUT","DELETE","PATCH","OPTIONS"].freeze
  HANDLERS = ["puma", "unicorn", "thin", "webrick"].freeze
  NOT_FOUND = [404, {"Content-Type" => "text/plain"}, ["Not found."]].freeze

  def self.new
    s = super
    s.instance_variable_set "@tree", Tree::TreeNode.new("ROOT", "ROOT")
    s.template if s.respond_to? :template
    s
  end

  def match http_method, path
    components = parse_path(path)
    matched_components = []
    
    walk = components.inject(@tree) do |node, component| 
      child = node[component]
      
      if child.nil?
        node
      else
        matched_components << component unless component == "/"
        child
      end
    end
    
    matched_path = "/" + matched_components.join("/")

    tc = walk.content
    
    return nil if tc == "ROOT"

    match = tc[http_method] # Check for route
    match ||= tc.items.select { |item| Sansom === item }.reject { |item| item.match(http_method,truncate_path(path, matched_path)).nil? }.first rescue nil # Check subsansoms
    match ||= tc.items.reject { |item| Sansom === item }.first rescue nil # Check for mounted rack apps
    [match, matched_path]
  end
  
  def call env
    return NOT_FOUND if @tree.children.empty?
    
    r = Rack::Request.new env

    m = match r.request_method, r.path_info
    item = m.first
    
    if item.nil?
      NOT_FOUND
    else
      case item
      when Proc
        item.call r
      when Sansom
        item.call(env.dup.merge({ "PATH_INFO" => truncate_path(r.path_info, m.last) }))
      else
        raise InvalidRouteError, "Invalid route handler, it must be a block (proc/lambda) or a subclass of Sansom."
      end
    end
  end
  
  def start port=3001
    raise NoRoutesError if @tree.children.empty?
    Rack::Handler.pick(HANDLERS).run self, :Port => port
  end
  
  def method_missing(meth, *args, &block)
    _args = args.dup.push block
    super unless _args.count >= 2 && map_path(meth, _args[0], _args[1])
  end
  
  private
  
  def parse_path path
    path.split("/").reject(&:empty?).unshift("/")
  end
  
  def truncate_path truncated, truncator
    "/" + parse_path(truncated)[parse_path(truncator).count..-1].join("/")
  end
  
  def map_path mapping, path, item
    return false if item == self
    
    verb = mapping.to_s.strip.upcase
    return false unless HTTP_VERBS.include?(verb) || mapping == :map
    verb = :map if mapping == :map
    
    components = parse_path path
    components.each_with_index.inject(@tree) do |node,(component, idx)|
      child = node[component]

      if child.nil?
        newvalue = Tree::TreeNode.new(component, TreeContent.new)
        node << newvalue
        child = newvalue
      end

      child.content[verb] = item if idx == components.count-1
      child
    end
    
    true
  end
end