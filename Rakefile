require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "nokogiri-happymapper"
    gem.summary = %Q{Provides a simple way to map XML to Ruby Objects}
    gem.description = "Object to XML Mapping Library, using Nokogiri (fork from John Nunemaker's Happymapper)"
    gem.email = "damien@meliondesign.com"
    gem.homepage = "http://github.com/dam5s/happymapper"
    gem.authors = ["Damien Le Berrigaud", "John Nunemaker", "David Bolton", "Roland Swingler", "Etienne Vallette d'Osia"]
    gem.add_dependency "nokogiri", "~> 1.4.2"
    gem.add_development_dependency "rspec", "~> 1.3.0"
    gem.files = FileList['lib/**/*.rb']
    gem.test_files = FileList['spec/**/*']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies
task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Nokogiri Happymapper #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
