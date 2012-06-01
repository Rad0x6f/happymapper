require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = '-c --format d'
end