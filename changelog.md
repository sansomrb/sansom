Changelog
=

0.0.1

(yanked due to bad name in Gemfile)

0.0.2

- Initial release

0.0.3

- Wrote custom tree implementation called Pine to replace RubyTree
- Added `before` block

Here's an example

    s = Sansom.new

    s.before do |r|
      # Caveat: routes are mapped before this block is called
      # Code executed before mapped route
    end
    
    s.get "/" do |r|
      [200, {}, ["Hello!"]]
    end
    
    s.start 2000