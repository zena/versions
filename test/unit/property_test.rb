require 'helper'
require 'property'

class PropertyTest < Test::Unit::TestCase
  class Version < ActiveRecord::Base
    self.table_name = :versions
    include Versions::Auto

    def should_clone?
      if changed?
        true
      else
        false
      end
    end
  end

  class Page < ActiveRecord::Base
    self.table_name = :pages
    include Versions::Multi
    has_multiple :versions, :class_name => 'PropertyTest::Version'

    include Property
    store_properties_in :version

    property do |p|
      p.text 'history'
      p.string 'author', :default => 'John Malkovitch'
    end
  end

  context 'Working with properties stored in version' do

    # should 'create an initial version' do
    #   page = nil
    #   assert_difference('PropertyTest::Version.count', 1) do
    #     page = Page.create('history' => 'His Story')
    #   end
    #   assert_equal 'His Story', page.history
    #   assert_equal 1, page.version.number
    # end

    should 'create new versions on property update' do
      page = Page.create('history' => 'His Story')
      assert_equal 1, page.versions.count
      assert page.update_attributes('history' => 'Her Story')
      assert_equal 'Her Story', page.history
      # page.version.properties_will_change!
      # page.version.save!
      assert_equal 2, page.versions.count
    end

    # should 'mark as dirty on property update' do
    #   page = Page.create('history' => 'His Story')
    #   page.prop['history'] = 'Her Story'
    #   assert page.changed?
    # end

    # should 'not create new versions on property update with same values' do
    #   page = Page.create('history' => 'His Story')
    #   assert_difference('PropertyTest::Version.count', 0) do
    #     assert page.update_attributes('history' => 'His Story')
    #   end
    #   assert_equal 1, page.version.number
    # end
  end
end
