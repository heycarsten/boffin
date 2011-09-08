require File.expand_path('../lib/boffin/version', __FILE__)

Gem::Specification.new do |s|
  s.name              = 'boffin'
  s.version           = Boffin::VERSION
  s.platform          = Gem::Platform::RUBY
  s.date              = Date.today.strftime('%F')
  s.homepage          = 'http://github.com/heycarsten/boffin'
  s.author            = 'Carsten Nielsen'
  s.email             = 'heycarsten@gmail.com'
  s.summary           = 'Hit tracking library for Ruby using Redis'
  s.has_rdoc          = 'yard'
  s.rubyforge_project = 'boffin'
  s.files             = `git ls-files`.split(?\n)
  s.test_files        = `git ls-files -- spec/*`.split(?\n)
  s.require_paths     = ['lib']

  s.add_dependency             'redis',   '>= 2.2'
  s.add_development_dependency 'rspec',   '~> 2.6'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'bundler', '~> 1.0.14'

  s.description = <<-END
Boffin is a library for tracking hits to things in your Ruby application. Things
can be IDs of records in a database, strings representing tags or topics, URLs
of webpages, names of places, whatever you desire. Boffin is able to provide
lists of those things based on most hits, least hits, it can even report on
weighted combinations of different types of hits.
  END
end
