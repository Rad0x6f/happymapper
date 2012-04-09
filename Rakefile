require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'
require 'yard'

task :default => :spec

RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = '-c --format d'
end

YARD::Rake::YardocTask.new do |yard|
  yard.files = ['lib/**/*.rb']
end