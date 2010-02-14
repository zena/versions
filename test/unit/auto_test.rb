require 'helper'

class AutoTest < Test::Unit::TestCase

  class BadVersion < ActiveRecord::Base
    set_table_name :versions
    include Versions::Auto
  end

  class Version < ActiveRecord::Base
    attr_accessor :should_clone, :messages
    include Versions::Auto

    def should_clone?
      @should_clone
    end

    def cloned
      @messages ||= []
      @messages << 'cloned'
    end
  end

  context 'An instance of a class with Auto included' do
    subject { @version }

    context 'without should_clone' do
      setup do
        @version = BadVersion.create('title' => 'Socrate')
      end

      should 'raise an exception on update' do
        assert_raise(NoMethodError) { subject.update_attributes('title' => 'Aristotle') }
      end
    end

    context 'with should_clone' do
      setup do
        @version = Version.create('title' => 'Socrate')
      end

      should 'start number at 1' do
        assert_equal 1, subject.number
      end

      context 'returning false' do
        should 'update record if should_clone is false' do
          assert_difference('Version.count', 0) do
            assert subject.update_attributes('title' => 'Aristotle')
          end
        end

        should 'not call cloned before saving' do
          assert_nil subject.messages
          subject.update_attributes('title' => 'Aristotle')
          assert_nil subject.messages
        end

        should 'return false on cloned?' do
          subject.update_attributes('title' => 'Aristotle')
          assert !subject.cloned?
        end

        should 'not increase version number' do
          assert_equal 1, subject.number
        end
      end

      context 'returning true' do
        setup do
          subject.should_clone = true
        end

        should 'duplicate record' do
          assert_difference('Version.count', 1) do
            assert subject.update_attributes('title' => 'Aristotle')
          end
        end

        should 'call cloned before saving' do
          assert_nil subject.messages
          subject.update_attributes('title' => 'Aristotle')
          assert_equal ['cloned'], subject.messages
        end

        should 'return true on cloned?' do
          subject.update_attributes('title' => 'Aristotle')
          assert subject.cloned?
        end

        should 'increase number on each clone' do
          subject.update_attributes('title' => 'Aristotle')
          assert_equal 2, subject.number

          subject.update_attributes('title' => 'Aristotle')
          assert_equal 3, subject.number
        end
      end
    end
  end
end
