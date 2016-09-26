# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'ragot/version'

Gem::Specification.new do |s|
  s.name          = "ragot"
  s.version       = Ragot::VERSION
  s.authors       = ["lacravate"]
  s.email         = ["lacravate@lacravate.fr"]
  s.homepage      = "https://github.com/lacravate/ragot"
  s.summary       = "A hack to create hooks around methods."
  s.description   = "A gem to tell on methods and what they do, behind their backs. A hack to create hooks around methods."

  s.files         = `git ls-files app lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']

  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'
end
