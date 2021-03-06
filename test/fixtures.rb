{:default=>[:"models.multi_test/simple_version.should not contain letter x", :"messages.should not contain letter x", "should not contain letter x"], :value=>"Fox", :scope=>[:activerecord, :errors], :model=>"Multitest::simpleversion", :attribute=>"Title"}

module I18n
  # I hate I18n in rails (soooo many bad surprises)
  def self.translate(key, options)
    if options[:default].first.to_s =~ /\A.*\.(.*)\Z/
      $1
    else
      options[:default].last
    end
  end
end

begin
  class VersionsMigration < ActiveRecord::Migration
    def self.down
      drop_table 'pages'
      drop_table 'versions'
    end
    def self.up
      create_table 'pages' do |t|
        t.integer 'version_id'
        t.string  'name'
        t.timestamps
      end

      create_table 'versions' do |t|
        t.string  'title'
        t.text    'text'
        t.string  'properties'
        t.integer 'attachment_id'
        t.integer 'number'
        t.integer 'page_id'
        t.integer 'node_id'
        t.timestamps
      end

      create_table 'attachments' do |t|
        t.string 'filename'
        t.timestamps
      end
    end
  end

  ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>':memory:')
  log_path = Pathname(__FILE__).dirname + '../log/test.log'
  Dir.mkdir(log_path.dirname) unless File.exist?(log_path.dirname)
  ActiveRecord::Base.logger = Logger.new(File.open(log_path, 'wb'))
  ActiveRecord::Migration.verbose = false
  VersionsMigration.migrate(:up)
  ActiveRecord::Migration.verbose = true
end