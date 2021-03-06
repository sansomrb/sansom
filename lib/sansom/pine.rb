#!/usr/bin/env ruby

# Tree data structure designed specifically for
# routing. It uses libpatternmatch (google it) to
# match paths with splats and mappings 
# 
# While other path routing software optimizes path parsing,
# Pine optimizes lookup and pattern matching. Pine takes
# logarithmic time in path matching and linear time in 
# path matching (libpatternmatch)

require_relative "./pine/node"

class Pine         
  def initialize
    @root = Pine::Node.new
    @cache = {}
  end
  
  def empty?
    @root.leaf?
  end
  
  # returns all non-root path components
  # path_comps("/my/path/")
  # => ["my", "path"]
  def path_comps path
    path.nil? || path.empty? ? [] : path[1..(path[-1] == "/" ? -2 : -1)].split('/')
  end
  
  # map_path "/food", Subsansom.new, :map
  # map_path "/", ObjectThatRespondsToCall.new, :get
  # it's also chainable
  def map_path path, handler, key
    @cache.clear

    node = (path == "/") ? @root : path_comps(path).inject(@root) { |n, comp| n << comp }

    if key == :mount && !handler.is_a?(Proc)
      if handler.singleton_class.include? Sansomable
        node.subsansoms << handler
      else
        node.rack_app = handler
      end
    else
      node.blocks[key] = handler
    end
    
    self
  end
  
  # match "/", :get
  def match path, verb
    return nil if empty?
    
    k = verb.to_s + path.to_s
    return @cache[k] if @cache.has_key? k
    
    matched_length = 0
    matched_params = { :splat => [] }
    matched_wildcard = false

    # find a matching node
    walk = path_comps(path).inject @root do |n, comp|
      c = n[comp]
      break n if c.nil?
      matched_length += comp.length+1
      if c.dynamic?
        matched_params.merge! c.mappings(comp)
        matched_params[:splat].push *c.splats(comp)
        matched_wildcard = true
      end
      c
    end
    
    return nil if walk.nil?

    remaining_path = path[matched_length..-1]
    match = walk.blocks[verb.downcase.to_sym]
    match ||= walk.subsansoms.detect { |i| i._pine.match remaining_path, verb }
    match ||= walk.rack_app

    return nil if match.nil?
    
    r = [match, remaining_path, path[0..matched_length-1], matched_params]
    @cache[k] = r unless matched_wildcard # Only cache static lookups (avoid huge memory usage)
    r
  end
end