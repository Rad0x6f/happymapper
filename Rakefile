require 'rubygems'
require 'rake'
require 'echoe'
require 'spec/rake/spectask'
require "lib/happymapper/version"

Echoe.new('nokogiri-happymapper', HappyMapper::Version) do |p|
  p.description     = "object to xml mapping library, using nokogiri (fork from John Nunemaker's Happymapper)"
  p.install_message = "May you have many happy mappings!"
  p.url             = "http://github.com/dam5s/happymapper"
  p.author          = "Damien Le Berrigaud, John Nunemaker, David Bolton"
  p.email           = "damien@meliondesign.com"
  p.extra_deps      = ['nokogiri >=1.4.0']
  p.need_tar_gz     = false
end

desc 'Preps the gem for a new release'
task :prepare do
  %w[manifest build_gemspec].each do |task|
    Rake::Task[task].invoke
  end
end

Rake::Task[:default].prerequisites.clear
task :default => :spec
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["spec/**/*_spec.rb"]
end
