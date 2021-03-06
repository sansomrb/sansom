# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "sansom"
  s.version       = "0.3.2"
  s.authors       = ["Nathaniel Symer"]
  s.email         = ["nate@natesymer.com"]
  s.summary       = "Scientific, philosophical, abstract web 'picowork' named after Sansom street in Philly, near where it was made."
  s.description   = s.summary + " " + "It's under 200 lines of code & it's lightning fast. It uses tree-based route resolution."
  s.homepage      = "http://github.com/fhsjaagshs/sansom"
  s.license       = "MIT"

  allfiles = `git ls-files -z`.split("\x0")
  s.files         = Dir.glob("{bin,lib,ext}/**/*")
  s.extensions    = ["ext/sansom/pine/extconf.rb"]
  s.executables   = allfiles.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = allfiles.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.6"
  s.add_dependency "rack", "~> 1"
end
