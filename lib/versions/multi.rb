module Versions
  # This module hides 'has_many' versions as if there was only a 'belongs_to' version,
  # automatically registering the latest version's id.
  module Multi
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def has_multiple(versions, options = {})
        name       = versions.to_s.singularize
        klass      = (options[:class_name] || name.capitalize).constantize
        owner_name = options[:inverse] || 'owner'

        raise TypeError.new("Missing 'number' field in table #{klass.table_name}.") unless klass.column_names.include?('number')
        raise TypeError.new("Missing '#{owner_name}_id' in table #{klass.table_name}.") unless klass.column_names.include?("#{owner_name}_id")

        has_many versions, :order => 'number DESC', :dependent => :destroy
        validate      :"validate_#{name}"
        after_create  :"save_#{name}_after_create"
        before_update :"save_#{name}_before_update"

        include module_for_multiple(name, klass, owner_name)
        klass.belongs_to owner_name, :class_name => self.to_s
      end

      protected
        def module_for_multiple(name, klass, owner_name)

          # Eval is ugly, but it's the fastest solution I know of
          line = __LINE__
          definitions = <<-EOF
            def #{name}                                     # def version
              @#{name} ||= begin                            #   @version ||= begin
                if v_id = #{name}_id                        #     if v_id = version_id
                  version = ::#{klass}.find(v_id)           #       version = ::Version.find(v_id)
                else                                        #     else
                  version = ::#{klass}.new                  #       version = ::Version.new
                end                                         #     end
                version.#{owner_name} = self                #     version.owner = self
                version                                     #     version
              end                                           #   end
            end                                             # end

            def #{name}=(v)                                 # def version=(v)
              @#{name} = v                                  #   @version = v
            end                                             # end

            def #{name}_attributes=(attributes)             # def version_attributes=(attributes)
              #{name}.attributes = attributes               #   version.attributes = attributes
            end                                             # end

            private
              def validate_#{name}                          # def validate_version
                unless #{name}.valid?                       #   unless version.valid?
                  merge_multi_errors('#{name}', @#{name})   #     merge_multi_errors('version', version)
                end                                         #   end
              end                                           # end

              def save_#{name}_before_update                # def save_version_before_update
                return true if !@#{name}.changed?           #   return true if !@version.changed?
                if !@#{name}.save(false)                    #   if !@version.save_with_validation(false)
                  merge_multi_errors('#{name}', @#{name})   #     merge_multi_errors('version', @version)
                  false                                     #     false
                else                                        #   else
                  set_current_#{name}_before_update         #     set_current_version_before_update
                  true                                      #     true
                end                                         #   end
              end                                           # end
                                                            #
              def save_#{name}_after_create                 # def save_version_after_create
                @#{name}.#{owner_name}_id = self[:id]       #   version.owner_id = self[:id]
                if !@#{name}.save(false)                    #   if !@version.save_with_validation(false)
                  merge_multi_errors('#{name}', @#{name})   #     merge_multi_errors('version', @version)
                  raise ActiveRecord::RecordInvalid.new(self) #   raise ActiveRecord::RecordInvalid.new(self)
                else                                        #   else
                  set_current_#{name}_after_create          #     set_current_version_after_create
                end                                         #   end
                true                                        #   true
              end                                           # end


              # This method is triggered when the version is saved, but before the
              # master record is updated. This method is usually overwritten
              # in the class.
              def set_current_#{name}_before_update         # def set_current_version_before_update
                self[:#{name}_id] = @#{name}.id             #   self[:version_id] = @version.id
              end                                           # end

              # This method is triggered when the version is saved, after the
              # master record has been created. This method is usually overwriten
              # in the class.
              def set_current_#{name}_after_create          # def set_current_version_after_create
                # raw SQL to skip callbacks and validtions  #
                conn = self.class.connection                #   conn = self.class.connection

                # conn.execute("UPDATE pages SET \#{conn.quote_column_name("version_id")} = \#{conn.quote(@version.id)} WHERE id = \#{conn.quote(self.id)}")
                conn.execute(
                  "UPDATE #{table_name} " +
                  "SET \#{conn.quote_column_name("#{name}_id")} = \#{conn.quote(@#{name}.id)} " +
                  "WHERE id = \#{conn.quote(self.id)}"
                )
                self[:#{name}_id] = @#{name}.id             #   self[:version_id] = @version.id
                changed_attributes.clear                    #   changed_attributes.clear
              end                                           # end
          EOF

          methods_module = Module.new
          methods_module.class_eval(definitions, __FILE__, line + 1)
          methods_module
        end # module_for_multiple
    end # ClassMethods

    private

      def merge_multi_errors(name, model)
        model.errors.each_error do |attribute, message|
          attribute = "#{name}_#{attribute}"
          errors.add(attribute, message) unless errors[attribute] # FIXME: rails 3: if errors[attribute].empty?
        end
      end
  end # Multi
end # Versions
