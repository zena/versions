module Versions
  # If you include this module in your model (which should also include Versions::Multi), deleting
  # the last version will destroy the model.
  module Destroy
    def self.included(base)
      base.class_eval do
        before_destroy :check_can_destroy
        alias_method_chain :attributes=, :destroy
      end
    end

    def attributes_with_destroy=(hash)
      if hash.delete(:__destroy) || hash.delete('__destroy')
        self.mark_for_destruction
      end
      self.attributes_without_destroy = hash
    end

    private
      # Default is to forbid destruction
      def check_can_destroy
        raise Exception.new("You should implement 'check_can_destroy' in #{self.class}")
      end
  end
end