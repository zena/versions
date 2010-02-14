begin
  class VersionsMigration < ActiveRecord::Migration
    def self.down
      drop_table 'pages'
      drop_table 'versions'
    end
    def self.up
      create_table 'pages' do |t|
        t.integer 'version_id'
        t.integer 'foo_id'
        t.string  'name'
        t.timestamps
      end

      create_table 'versions' do |t|
        t.string  'title'
        t.text    'text'
        t.string  'properties'
        t.integer 'attachment_id'
        t.integer 'number'
        t.integer 'owner_id'
        t.timestamps
      end

      create_table 'attachments' do |t|
        t.string 'owner_table'
        t.string 'filename'
        t.timestamps
      end
    end
  end

  ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>':memory:')
  ActiveRecord::Migration.verbose = false
  VersionsMigration.migrate(:up)
  ActiveRecord::Migration.verbose = true
end