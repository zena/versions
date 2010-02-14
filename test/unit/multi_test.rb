require 'helper'

class MultiTest < Test::Unit::TestCase
  class SimpleVersion < ActiveRecord::Base
    set_table_name :versions
  end
  class SimplePage < ActiveRecord::Base
    set_table_name :pages
    include Versions::Multi
    has_multiple :foos, :class_name => 'MultiTest::SimpleVersion'
  end

  class Version < ActiveRecord::Base
    set_table_name :versions
    include Versions::Auto
    def should_clone?
      changed?
    end
  end
  class Page < ActiveRecord::Base
    set_table_name :pages
    include Versions::Multi
    has_multiple :versions, :class_name => 'MultiTest::Version'
  end

  context 'A class with multiple foos' do

    should 'accept foo nested attributes' do
      assert_nothing_raised { SimplePage.create('name' => 'one', 'foo_attributes' => {'title' => 'First'}) }
    end

    should 'create a foo instance of the given type' do
      page = SimplePage.create
      assert page.valid?
      assert_kind_of MultiTest::SimpleVersion, page.foo
    end

    should 'replace current instance on new foos' do
      page = SimplePage.create
      first_foo = page.foo.id
      page.foo = SimpleVersion.new
      assert page.save
      page = SimplePage.find(page.id)
      assert_not_equal first_foo, page.foo.id
    end
  end

  context 'A class with multiple versions' do
    should 'create new versions on update' do
      page = Page.create
      assert_difference('Version.count', 1) do
        assert page.update_attributes('version_attributes' => {'title' => 'newTitle'})
      end
    end
  end
end