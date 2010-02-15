module Versions
  # When you include this module into a class, it will automatically clone itself
  # depending on the call to should_clone?
  module Auto
    attr_reader :previous_id

    def self.included(base)
      raise TypeError.new("Missing 'number' field in table #{base.table_name}.") unless base.column_names.include?('number')
      base.before_save :prepare_save_or_clone
      base.after_save  :clear_number_counter
      base.attr_protected :number
    end

    def should_clone?
      # Always clone on update
      true
    end

    # This method provides a hook to alter values after a clone operation (just before save: no validation).
    def cloned
    end

    # Return true if the record was cloned just before the last save
    def cloned?
      !@previous_id.nil?
    end

    def prepare_save_or_clone
      if new_record?
        self[:number] = 1
      elsif changed? && should_clone?
        @previous_id = self[:id]
        @previous_number ||= self[:number]
        self[:number] = @previous_number + 1

        self[:id] = nil
        self[:created_at] = nil
        self[:updated_at] = nil
        @new_record = true
        cloned
      else
        @previous_id = nil
      end
      true
    end

    def clear_number_counter
      @previous_number = nil
      true
    end
  end # Auto
end # Versions
