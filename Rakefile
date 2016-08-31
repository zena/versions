require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  'lib').expand_path)

require 'versions/version'
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
    test.pattern = 'test/**/**_test.rb'
    test.verbose = true
    test.rcov_opts = ['-T', '--exclude-only', '"test\/,^\/"']
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

task :default => :test

