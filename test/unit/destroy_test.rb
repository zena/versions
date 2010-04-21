require 'helper'

class DestroyTest < Test::Unit::TestCase
  class Version < ActiveRecord::Base
    attr_accessor :can_destroy
    set_table_name :versions
    include Versions::Auto
    include Versions::Destroy

    def check_can_destroy
      defined?(@can_destroy) ? @can_destroy : true
    end
  end

  class Page < ActiveRecord::Base
    set_table_name :pages
    include Versions::Multi
    has_multiple :versions, :class_name => 'DestroyTest::Version'
  end

  class VersionWithoutCanDestroy < ActiveRecord::Base
    attr_accessor :can_destroy
    set_table_name :versions
    include Versions::Auto
    include Versions::Destroy
  end

  class Page2 < ActiveRecord::Base
    set_table_name :pages
    include Versions::Multi
    has_multiple :versions, :class_name => 'DestroyTest::VersionWithoutCanDestroy', :foreign_key => 'page_id'
  end

  context 'A page with a version' do
    subject do
      Page.create('name' => 'one', 'version_attributes' => {'title' => 'First'})
    end

    should 'destroy version on __destroy nested attribute' do
      subject
      assert_difference('Version.count', -1) do
        subject.update_attributes('version_attributes' => {:__destroy => true})
      end
    end

    should 'not destroy if not allowed' do
      subject.version.can_destroy = false
      assert_difference('Version.count', 0) do
        subject.update_attributes('version_attributes' => {:__destroy => true})
      end
    end
  end # A page with a version

  context 'A version without can destroy' do
    subject do
      Page2.create('name' => 'one', 'version_attributes' => {'title' => 'First'})
    end

    should 'raise an exception on __destroy' do
      assert_raise(Exception) do
        subject.update_attributes('version_attributes' => {:__destroy => true})
      end
    end
  end

  context 'A page with many versions' do
    subject do
      p = Page.create('name' => 'one', 'version_attributes' => {'title' => 'first'})
      p.update_attributes('version_attributes' => {'title' => 'second'})
      p
    end

    should 'remove version from versions on destroy' do
      # This also loads versions association
      assert_equal 2, subject.versions.count

      assert_difference('Version.count', -1) do
        subject.update_attributes('version_attributes' => {'__destroy' => true})
      end

      assert_equal 1, subject.versions.count
      assert_equal 'first', subject.versions.first.title
    end
    
    should 'update current version on destroy' do
      old_version_id = subject.version_id
      
      assert subject.update_attributes('version_attributes' => {'__destroy' => true})

      assert_not_equal old_version_id, subject.version_id
      assert_equal 'first', subject.version.title
    end
  end # A page with a version
end