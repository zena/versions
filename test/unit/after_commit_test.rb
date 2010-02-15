require 'helper'

class AfterCommitTest < Test::Unit::TestCase
  class Page < ActiveRecord::Base
    attr_accessor :actions
    before_save :do_action
    after_save  :raise_to_rollback
    validates_presence_of :name

    def after_commit_actions
      @after_commit_actions ||= []
    end

    private
      def do_action
        after_commit do
          after_commit_actions << 'executed'
        end
      end

      def raise_to_rollback
        raise ActiveRecord::Rollback if self[:name] == 'raise'
      end
  end

  context 'Creating a valid page' do
    should 'trigger after_commit once all is done' do
      page = Page.create(:name => 'hello')
      assert_equal ['executed'], page.after_commit_actions
    end

    context 'inside a transaction' do
      should 'trigger after_commit after last transaction' do
        page = nil
        Page.transaction do
          page = Page.create(:name => 'hello')
          assert_equal [], page.after_commit_actions
        end
        assert_equal ['executed'], page.after_commit_actions
      end

      should 'not trigger after_commit if outer transaction fails' do
        page = nil
        begin
          Page.transaction do
            page = Page.create(:name => 'hello')
            assert_equal [], page.after_commit_actions
            raise 'Something went bad'
          end
        rescue Exception => err
        end
        assert_equal [], page.after_commit_actions
      end

      should 'not trigger after_commit on rollback' do
        page = nil
        Page.transaction do
          page = Page.create(:name => 'hello')
          assert_equal [], page.after_commit_actions
          raise ActiveRecord::Rollback
        end
        assert_equal [], page.after_commit_actions
      end

      should 'clear after_commit after transaction' do
        actions = []
        Page.transaction do
          Page.after_commit do
            actions << 'executed'
          end
          raise ActiveRecord::Rollback
        end
        assert_equal [], actions

        Page.transaction do
        end
        assert_equal [], actions
      end

    end
  end

  context 'Creating an invalid page' do
    should 'not trigger after_commit' do
      page = Page.create
      assert page.new_record?
      assert_equal [], page.after_commit_actions
    end
  end

  context 'Raising an error after save' do
    should 'not trigger after_commit' do
      page = Page.create(:name => 'raise')
      assert_equal [], page.after_commit_actions
    end
  end

  should 'not allow after commit outside of a transaction' do
    assert_raise(Exception) do
      Page.new.instance_eval do
        after_commit do
          # never executed
        end
      end
    end
  end
end
