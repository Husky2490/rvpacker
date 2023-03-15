# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rvpacker/version'

Gem::Specification.new do |spec|
  spec.name          = 'rvpacker'
  spec.version       = Rvpacker::VERSION
  spec.authors       = ["Howard Jeng", "Andrew Kesterson", 'Solistra', 'Husky2490']
  spec.email         = ['rsyanez99@gmail.com']
  spec.summary       = %q{Pack and unpack RPG Maker data files}
  spec.homepage      = "https://github.com/Husky2490/rvpacker"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "optimist"
  spec.add_dependency "psych", [">= 3.0.0", "< 3.2.0"]
  spec.add_dependency "formatador"
  spec.add_dependency "scanf"
end
