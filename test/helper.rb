require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'active_record'
require 'active_support'
require 'active_support/testing/assertions'
require 'tempfile'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'versions'
require 'fixtures'

class Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  FILE_FIXTURES_PATH = Pathname(__FILE__).dirname + 'fixtures/files'

  # taken from http://manuals.rubyonrails.com/read/chapter/28#page237 with some modifications
  def uploaded_fixture(fname, content_type="application/octet-stream", filename=nil)
    path = File.join(FILE_FIXTURES_PATH, fname)
    filename ||= File.basename(path)
    # simulate small files with StringIO
    if File.stat(path).size < 1024
      # smaller then 1 Ko
      t = StringIO.new(File.read(path))
    else
      t = Tempfile.new(fname)
      FileUtils.copy_file(path, t.path)
    end
    uploaded_file(t, filename, content_type)
  end

  # JPEG helper
  def uploaded_jpg(fname, filename=nil)
    uploaded_fixture(fname, 'image/jpeg', filename)
  end

  private
    def uploaded_file(file, filename = nil, content_type = nil)
      (class << file; self; end;).class_eval do
        alias local_path path if respond_to?(:path)  # FIXME: do we need this ?
        define_method(:original_filename) { filename }
        define_method(:content_type) { content_type }
      end
      file
    end
end
