module Versions
  # If you include this module in your model (which should also include Versions::Multi), deleting
  # the last version will destroy the model.
  module Destroy
    
    # This module should be included in the model that serves as version.
    module Version
      def self.included(base)

        base.class_eval do
          attr_accessor :__destroy
          belongs_to :node
          before_create :setup_version_on_create
          attr_protected :number, :user_id

          alias_method_chain :save, :destroy
        end
      end

      def save_with_destroy(*args)
        if @__destroy
          node = self.node
          if destroy
            # reset @version
            node.send(:version_destroyed)
            true
          end
        else
          save_without_destroy(*args)
        end
      end

      private
        def setup_version_on_create
          raise "You should define 'setup_version_on_create' method in '#{self.class}' class."
        end
    end

    def self.included(base)
      base.alias_method_chain :save, :destroy
    end

    def save_with_destroy(*args)
      version = self.version
      # TODO: we could use 'version.mark_for_destruction' instead of __destroy...
      if version.__destroy && versions.count == 1
        destroy # will destroy last version
      else
        save_without_destroy(*args)
      end
    end
    
    private
      # This is called after a version is destroyed
      def version_destroyed
        # remove from versions list
        if versions.loaded?
          node.versions -= [@version]
        end
      end

  end
end