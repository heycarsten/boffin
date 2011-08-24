require File.expand_path('../lib/boffin/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'boffin'
  s.version       = Boffin::VERSION
  s.date          = Date.today.strftime('%F')

  s.homepage      = 'http://github.com/heycarsten/boffin'
  s.email         = 'heycarsten@gmail.com'
  s.authors       = ['Carsten Nielsen']
  s.summary       = 'Boffin tracks hits to your Ruby objects with Redis for trending and top lists.'

  s.files         = `git ls-files`.split(?\n)
  s.test_files    = `git ls-files -- spec/*`.split(?\n)
  s.require_paths = ['lib']

  s.add_dependency 'redis', '> 2.2'

  s.add_development_dependency 'rspec',  '~> 2.6'
  s.add_development_dependency 'timecop'

  s.description = <<END
Boffin uses Redis to track hits on Ruby objects, these can be models, or even
just strings. You can then query for top objects based on hit type, or you can
combine hits together and even apply weights to favour a certain type of hit
over other types.
END
end
