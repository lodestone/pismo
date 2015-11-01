# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pismo/version"

Gem::Specification.new do |s|
  s.name        = "pismo"
  s.version     = Pismo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Peter Cooper"]
  s.email       = ["git@peterc.org"]
  s.homepage    = "http://github.com/peterc/pismo"
  s.description = %q{Pismo extracts and retrieves content-related metadata from HTML pages - you can use the resulting data in an organized way, such as a summary/first paragraph, body text, keywords, RSS feed URL, favicon, etc.}
  s.summary     = %q{Extracts or retrieves content-related metadata from HTML pages}
  s.date        = %q{2010-12-19}
  s.default_executable = %q{pismo}

  s.rubyforge_project = "pismo"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|plugins)/}) }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency(%q<mocha>, [">= 0"])
  s.add_development_dependency('rake', '~> 10')
  s.add_development_dependency('rspec', "~> 3.3")
  s.add_dependency('nokogiri', '~> 1.6')
  s.add_dependency('phrasie', '~> 0.1')
  s.add_dependency('fastimage', '~> 1.7')
  s.add_dependency('htmlentities', '~> 4.3')
end
