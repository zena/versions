require 'helper'

class MultiTest < Test::Unit::TestCase
  class SimpleVersion < ActiveRecord::Base
    set_table_name :versions
    validate :title_does_not_contain_letter_x
    before_save :fail_if_title_contains_y

    def title_does_not_contain_letter_x
      errors.add('title', 'should not contain letter x') if self[:title].to_s =~ /x/
    end

    def fail_if_title_contains_y
      if self[:title].to_s =~ /y/
        errors.add('title', 'should not contain letter y')
        false
      else
        true
      end
    end
  end
  class SimplePage < ActiveRecord::Base
    include Versions::Multi

    set_table_name :pages
    has_multiple :foos, :class_name => 'MultiTest::SimpleVersion', :inverse => 'node'
  end

  class Version < ActiveRecord::Base
    set_table_name :versions
    include Versions::Auto
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

    should 'set foo_id after_create' do
      page = SimplePage.create
      foo_id = page.foo_id
      assert foo_id
      page = SimplePage.find(page)
      assert_equal foo_id, page.foo_id
    end

    should 'replace current instance on new foos' do
      page = SimplePage.create
      first_foo = page.foo.id
      page.foo = SimpleVersion.new('title' => 'hello')
      assert page.save
      page = SimplePage.find(page.id)
      assert_not_equal first_foo, page.foo.id
    end

    should 'merge foo errors in model on create' do
      page = SimplePage.create('foo_attributes' => {'title' => 'Fox'})
      assert !page.valid?
      assert_equal 'should not contain letter x', page.errors['foo_title']
    end

    should 'merge foo errors in model on update' do
      page = SimplePage.create('foo_attributes' => {'title' => 'phone'})
      assert page.valid?
      assert !page.update_attributes('foo_attributes' => {'title' => 'fax'})
      assert_equal 'should not contain letter x', page.errors['foo_title']
    end

    should 'rollback if foo save fails on create' do
      page = nil
      assert_difference('MultiTest::SimpleVersion.count', 0) do
        assert_difference('MultiTest::SimplePage.count', 0) do
          page = SimplePage.new('foo_attributes' => {'title' => 'Fly'})
          assert !page.save
          assert_contains page.errors.full_messages, 'Foo title should not contain letter y'
        end
      end
    end

    should 'abort if foo save fails on update' do
      page = SimplePage.create('foo_attributes' => {'title' => 'mosquito'})
      assert page.valid?
      assert !page.update_attributes('foo_attributes' => {'title' => 'fly'})
      assert_equal 'should not contain letter y', page.errors['foo_title']
    end

    should 'find owner back using inverse' do
      page = SimplePage.create
      assert_equal page, page.foo.node
    end

    should 'list foos' do
      page = SimplePage.create('foo_attributes' => {'title' => 'One'})
      page.foo = SimpleVersion.new('title' => 'Two')
      page.save
      assert_equal 2, page.foos.size
    end
  end

  context 'A class with multiple auto versions' do
    should 'create new versions on update' do
      page = Page.create
      assert_difference('Version.count', 1) do
        assert page.update_attributes('version_attributes' => {'title' => 'newTitle'})
      end
    end

    should 'mark new version as not dirty after create' do
      page = Page.create
      assert !page.version.changed?
    end

    should 'mark new version as not dirty after update' do
      page = Page.create
      assert page.update_attributes('version_attributes' => {'title' => 'Yodle'})
      assert !page.version.changed?
    end

    should 'find latest version' do
      page = Page.create
      v_id = page.version.id
      assert page.update_attributes('version_attributes' => {'title' => 'newTitle'})
      assert_not_equal v_id, page.version.id
    end

    should 'not create new versions on update if content did not change' do
      page = Page.create('version_attributes' => {'title' => 'One'})
      assert_difference('Version.count', 0) do
        assert page.update_attributes('version_attributes' => {'title' => 'One'})
      end
    end


    should 'list versions' do
      page = Page.create('version_attributes' => {'title' => 'One'})
      assert page.update_attributes('version_attributes' => {'title' => 'Two'})
      assert page.update_attributes('version_attributes' => {'title' => 'Three'})
      assert_equal 3, page.versions.size
    end
  end

  context 'Defining association with custom foreign_key' do
    should 'not raise an exception if the key exists' do
      assert_nothing_raised do
        class Book < ActiveRecord::Base
          set_table_name :pages
          include Versions::Multi
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => 'big_book', :foreign_key => 'node_id'
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => :big_book, :foreign_key => :node_id
        end
      end
    end

    should 'raise an exception if the key does not exist' do
      assert_raise(TypeError) do
        class Book < ActiveRecord::Base
          set_table_name :pages
          include Versions::Multi
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => 'big_book', :foreign_key => 'bug_id'
        end
      end

      assert_raise(TypeError) do
        class Book < ActiveRecord::Base
          set_table_name :pages
          include Versions::Multi
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => :big_book, :foreign_key => :bug_id
        end
      end
    end
  end
end