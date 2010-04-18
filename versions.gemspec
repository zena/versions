# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{versions}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2010-04-18}
  s.description = %q{A list of libraries to work with ActiveRecord model versioning: Auto (duplicate on save), Multi (hide many versions behind a single one), Transparent (hide versions from outside world), Property (define properties on model, store them in versions)}
  s.email = %q{gaspard@teti.ch}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "History.txt",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "lib/versions.rb",
     "lib/versions/after_commit.rb",
     "lib/versions/attachment.rb",
     "lib/versions/auto.rb",
     "lib/versions/destroy.rb",
     "lib/versions/multi.rb",
     "lib/versions/shared_attachment.rb",
     "lib/versions/version.rb",
     "test/fixtures.rb",
     "test/fixtures/files/bird.jpg",
     "test/fixtures/files/lake.jpg",
     "test/helper.rb",
     "test/unit/after_commit_test.rb",
     "test/unit/attachment_test.rb",
     "test/unit/auto_test.rb",
     "test/unit/multi_test.rb",
     "test/unit/property_test.rb",
     "test/unit/transparent_test.rb",
     "versions.gemspec"
  ]
  s.homepage = %q{http://zenadmin.org/650}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A list of libraries to work with ActiveRecord model versioning}
  s.test_files = [
    "test/fixtures.rb",
     "test/helper.rb",
     "test/unit/after_commit_test.rb",
     "test/unit/attachment_test.rb",
     "test/unit/auto_test.rb",
     "test/unit/multi_test.rb",
     "test/unit/property_test.rb",
     "test/unit/transparent_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<property>, [">= 0.8.1"])
      s.add_development_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<property>, [">= 0.8.1"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<property>, [">= 0.8.1"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
  end
end

