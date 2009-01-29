# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{happymapper}
  s.version = "0.1.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = %q{2009-01-28}
  s.description = %q{object to xml mapping library}
  s.email = %q{nunemaker@gmail.com}
  s.extra_rdoc_files = ["lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/happymapper.rb", "lib/libxml_ext/libxml_helper.rb", "README", "TODO"]
  s.files = ["examples/amazon.rb", "examples/current_weather.rb", "examples/post.rb", "examples/twitter.rb", "History", "lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/happymapper.rb", "lib/libxml_ext/libxml_helper.rb", "License", "Manifest", "Rakefile", "README", "spec/fixtures/address.xml", "spec/fixtures/current_weather.xml", "spec/fixtures/pita.xml", "spec/fixtures/posts.xml", "spec/fixtures/radar.xml", "spec/fixtures/statuses.xml", "spec/happymapper_attribute_spec.rb", "spec/happymapper_element_spec.rb", "spec/happymapper_item_spec.rb", "spec/happymapper_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "TODO", "website/css/common.css", "website/index.html", "happymapper.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://happymapper.rubyforge.org}
  s.post_install_message = %q{May you have many happy mappings!}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Happymapper", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{happymapper}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{object to xml mapping library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<libxml-ruby>, [">= 0.9.7"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
    else
      s.add_dependency(%q<libxml-ruby>, [">= 0.9.7"])
      s.add_dependency(%q<echoe>, [">= 0"])
    end
  else
    s.add_dependency(%q<libxml-ruby>, [">= 0.9.7"])
    s.add_dependency(%q<echoe>, [">= 0"])
  end
end
