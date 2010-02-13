require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  'lib').expand_path)

require 'versions'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs     << 'lib' << 'test'
  test.pattern  = 'test/**/**_test.rb'
  test.verbose  = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test' << 'lib'
    test.pattern = 'test/**/auto_test.rb'
    test.verbose = true
    test.rcov_opts = ['-T', '--exclude-only', '"test\/,^\/"']
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

task :default => :test

# GEM management
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "versions"
    gemspec.summary = %Q{A list of usefull libraries to work with ActiveRecord model versioning}
    gemspec.description = %Q{A list of usefull libraries to work with ActiveRecord model versioning}
    gemspec.email = "gaspard@teti.ch"
    gemspec.homepage = "http://github.com/zena/versions"
    gemspec.authors = ["Gaspard Bucher"]
    gemspec.add_development_dependency "shoulda", ">= 0"

    gemspec.add_development_dependency('shoulda')
    gemspec.add_dependency('activerecord')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end