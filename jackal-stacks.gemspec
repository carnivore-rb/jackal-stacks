$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'jackal-stacks/version'
Gem::Specification.new do |s|
  s.name = 'jackal-stacks'
  s.version = Jackal::Stacks::VERSION.version
  s.summary = 'Message processing helper'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/carnivore-rb/jackal-stacks'
  s.description = 'Build stuff!'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_runtime_dependency 'jackal'
  s.add_runtime_dependency 'batali'
  s.add_runtime_dependency 'sfn'
  s.files = Dir['lib/**/*'] + %w(jackal-stacks.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
