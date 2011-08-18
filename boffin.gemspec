# coding: utf-8
require File.expand_path('../lib/boffin/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'boffin'
  s.version     = Boffin::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Carsten Nielsen']
  s.email       = ['heycarsten@gmail.com']
  s.homepage    = 'http://github.com/heycarsten/boffin'
  s.summary     = %q{Track hits to your models for trends and hit counts}
  s.description = %q{}

  s.required_rubygems_version = '>= 1.8.5'
  s.rubyforge_project = 'boffin'

  s.add_dependency 'redis'

  s.files         = `git ls-files`.split(?\n)
  s.test_files    = `git ls-files -- spec/*`.split(?\n)
  s.require_paths = ['lib']
end
