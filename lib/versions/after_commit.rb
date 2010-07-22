require 'active_record/connection_adapters/abstract_adapter'
module AfterCommit
  module Initializer
    def self.included(base)
      base.alias_method_chain :new_connection, :after_commit
    end
    private
      def new_connection_with_after_commit(*args)
        conn = new_connection_without_after_commit(*args)
        conn.class_eval do
          include AfterCommit::Connection
        end
        conn
      end
  end

  module Connection
    def self.included(base)
      base.alias_method_chain :commit_db_transaction, :after_commit
      base.alias_method_chain :transaction, :after_commit
    end

    def after_commit(&block)
      if block_given?
        if open_transactions == 0
          raise Exception.new("'after_commit' should only be used inside a transaction")
        else
          (@after_commit ||= []) << block
        end
      end
    end

    def commit_db_transaction_with_after_commit
      after_commit_actions = @after_commit
      @after_commit = nil
      commit_db_transaction_without_after_commit
      if after_commit_actions
        after_commit_actions.each do |block|
          block.call
        end
      end
    end

    def transaction_with_after_commit(*args, &block)
      transaction_without_after_commit(*args, &block)
    ensure
      @after_commit = nil if open_transactions == 0
    end
  end

  module ModelMethods
    module ClassMethods
      def after_commit(&block)
        connection.after_commit(&block)
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    def after_commit(&block)
      self.class.connection.after_commit(&block)
    end
  end
end

raise "AfterCommit required too late, connection already active." if Class.new(ActiveRecord::Base).connected?
ActiveRecord::ConnectionAdapters::ConnectionPool.send(:include, AfterCommit::Initializer)
ActiveRecord::Base.send(:include, AfterCommit::ModelMethods)