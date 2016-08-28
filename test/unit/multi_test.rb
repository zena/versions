require 'helper'

class MultiTest < Test::Unit::TestCase
  class SimpleVersion < ActiveRecord::Base
    self.table_name = :versions
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
    self.table_name = :pages
    include Versions::Multi

    has_multiple :simple_versions, :class_name => 'MultiTest::SimpleVersion', :inverse => 'node', :local_key => 'version_id'
  end

  class Version < ActiveRecord::Base
    self.table_name = :versions
    include Versions::Auto
  end

  class Page < ActiveRecord::Base
    self.table_name = :pages
    include Versions::Multi
    has_multiple :versions, :class_name => 'MultiTest::Version'
  end

  context 'Creating a page with versions' do
    should 'accept simple_version nested attributes' do
      assert_nothing_raised { SimplePage.create('name' => 'one', 'simple_version_attributes' => {'title' => 'First'}) }
    end

    should 'create a simple_version instance of the given type' do
      page = SimplePage.create
      assert page.valid?
      assert_kind_of MultiTest::SimpleVersion, page.simple_version
    end

    should 'set version_id after_create' do
      page = SimplePage.create
      version_id = page.version_id
      assert version_id
      page = SimplePage.find(page)
      assert_equal version_id, page.version_id
    end

    should 'replace current instance on new simple_versions' do
      page = SimplePage.create
      first_simple_version = page.simple_version.id
      page.simple_version = SimpleVersion.new('title' => 'hello')
      assert page.save
      page = SimplePage.find(page.id)
      assert_not_equal first_simple_version, page.simple_version.id
    end

    should 'merge simple_version errors in model on create' do
      page = SimplePage.create('simple_version_attributes' => {'title' => 'Fox'})
      assert !page.valid?
      assert_equal 'should not contain letter x', page.errors['simple_version_title']
    end

    should 'merge simple_version errors in model on update' do
      page = SimplePage.create('simple_version_attributes' => {'title' => 'phone'})
      assert page.valid?
      assert !page.update_attributes('simple_version_attributes' => {'title' => 'fax'})
      assert_equal 'should not contain letter x', page.errors['simple_version_title']
    end

    should 'rollback if simple_version save fails on create' do
      page = nil
      assert_difference('MultiTest::SimpleVersion.count', 0) do
        assert_difference('MultiTest::SimplePage.count', 0) do
          page = SimplePage.new('simple_version_attributes' => {'title' => 'Fly'})
          assert !page.save
          assert_contains page.errors[:simple_version_title], 'should not contain letter y'
        end
      end
    end

    should 'abort if version save fails on update' do
      page = SimplePage.create('simple_version_attributes' => {'title' => 'mosquito'})
      assert page.valid?
      assert !page.update_attributes('simple_version_attributes' => {'title' => 'fly'})
      assert_equal 'should not contain letter y', page.errors['simple_version_title']
    end

    should 'find owner back using inverse' do
      page = SimplePage.create
      assert_equal page, page.simple_version.node
    end

    should 'list simple_versions' do
      page = SimplePage.create('simple_version_attributes' => {'title' => 'One'})
      page.simple_version = SimpleVersion.new('title' => 'Two')
      page.save
      assert_equal 2, page.simple_versions.size
    end
  end # Creating a page with versions

  context 'A simple page with a version' do
    subject do
      p = SimplePage.create('simple_version_attributes' => {'title' => 'Buz'})
      SimplePage.find(p.id)
    end

    should 'save without validations' do
      subject.name = 'hop'
      assert_difference('SimpleVersion.count', 0) do
        assert subject.save_with_validation(false)
      end
    end
  end # A page with a version

  context 'Creating an object with multiple auto versions' do

    should 'mark new version as not dirty after create' do
      page = Page.create
      assert !page.version.changed?
    end

    should 'mark new version as not dirty after update' do
      page = Page.create
      assert page.update_attributes('version_attributes' => {'title' => 'Yodle'})
      assert !page.version.changed?
    end

    should 'not create new versions on update if content did not change' do
      page = Page.create('version_attributes' => {'title' => 'One'})
      assert_difference('Version.count', 0) do
        assert page.update_attributes('version_attributes' => {'title' => 'One'})
      end
    end
  end

  context 'A page' do

    context 'with a version' do
      subject do
        p = Page.create('version_attributes' => {'title' => 'Fly'})
        Page.find(p.id)
      end

      should 'create new versions on update' do
        subject # create
        assert_difference('Version.count', 1) do
          assert subject.update_attributes('version_attributes' => {'title' => 'newTitle'})
        end
      end

      should 'save without validations' do
        subject.name = 'hop'
        assert_difference('Version.count', 0) do
          assert subject.save_with_validation(false)
        end
      end

      should 'find latest version' do
        v_id = subject.version.id
        assert subject.update_attributes('version_attributes' => {'title' => 'newTitle'})
        assert_not_equal v_id, subject.version.id
      end


      should 'save master model if version only changed' do
        subject # create
        assert_difference('Version.count', 1) do
          assert subject.update_attributes('version_attributes' => {'title' => 'Two'})
        end
      end
    end

    context 'with many versions' do
      subject do
        page = Page.create('version_attributes' => {'title' => 'One'})
        page.update_attributes('version_attributes' => {'title' => 'Two'})
        page.update_attributes('version_attributes' => {'title' => 'Three'})
        page
      end

      should 'list versions' do
        assert_equal 3, subject.versions.size
      end
    end # with many versions
  end # A page with a version

  context 'Defining association with custom foreign_key' do
    should 'not raise an exception if the key exists' do
      assert_nothing_raised do
        class Book < ActiveRecord::Base
          self.table_name = :pages
          include Versions::Multi
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => 'big_book', :foreign_key => 'node_id'
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => :big_book, :foreign_key => :node_id
        end
      end
    end

    should 'raise an exception if the key does not exist' do
      assert_raise(TypeError) do
        class Book < ActiveRecord::Base
          self.table_name = :pages
          include Versions::Multi
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => 'big_book', :foreign_key => 'bug_id'
        end
      end

      assert_raise(TypeError) do
        class Book < ActiveRecord::Base
          self.table_name = :pages
          include Versions::Multi
          has_multiple :versions, :class_name => 'MultiTest::SimpleVersion', :inverse => :big_book, :foreign_key => :bug_id
        end
      end
    end
  end
end