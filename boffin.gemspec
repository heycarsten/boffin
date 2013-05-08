lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boffin/version'

Gem::Specification.new do |s|
  s.name     = 'boffin'
  s.version  = Boffin::VERSION
  s.homepage = 'http://github.com/heycarsten/boffin'
  s.authors  = ['Carsten Nielsen']
  s.email    = ['heycarsten@gmail.com']
  s.summary  = 'Hit tracking library for Ruby using Redis'
  s.has_rdoc = 'yard'
  s.license  = 'MIT'
  s.description = <<-END
Boffin is a library for tracking hits to things in your Ruby application. Things
can be IDs of records in a database, strings representing tags or topics, URLs
of webpages, names of places, whatever you desire. Boffin is able to provide
lists of those things based on most hits, least hits, it can even report on
weighted combinations of different types of hits.
  END

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rspec',   '~> 2.13'
  s.add_development_dependency 'timecop'

  s.add_dependency 'redis',   '~> 3.0'
end
