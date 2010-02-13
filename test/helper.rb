require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'active_record'
require 'active_support'
require 'active_support/testing/assertions'
require 'versions'
require 'fixtures'

class Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
end
