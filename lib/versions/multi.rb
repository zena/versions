module Versions
  # This module hides 'has_many' versions as if there was only a 'belongs_to' version,
  # automatically registering the latest version's id.
  module Multi
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # Hide many instances behind a single current one.
      # === Example
      # A page with many versions and a current one representing the latest content:
      # <tt>has_multiple :versions</tt>
      #
      # === Supported options
      # [:class_name]
      #   Specify the class name of the association. Use it only if that name can't be inferred
      #   from the association name. So <tt>has_multiple :versions</tt> will by default be linked to the Version class
      # [:inverse]
      #   Specify the name of the relation from the associated record back to this record. By default the name
      #   will be infered from the name of the current class. Note that this setting also defines the default
      #   the foreign key name.
      # [:foreign_key]
      #   Specify the foreign key used for the association. By default this is guessed to be the name of this class
      #   (or the inverse) in lower-case and "_id" suffixed. So a Person class that makes a +has_multiple+ association will
      #   use "person_id" as the default <tt>:foreign_key</tt>.
      # [:local_key]
      #   Specify the local key to retrieve the current associated record. By default this is guessed from the name of the
      #   association in lower-case and "_id" suffixed. So a model that <tt>has_multiple :pages</tt> would use "page_id" as
      #   local key to get the current page. Note that the local key does not need to live in the database if the model
      #   defines <tt>set_current_[assoc]_before_update</tt> and <tt>set_current_[assoc]_after_create</tt> where '[assoc]'
      #   represents the association name.
      def has_multiple(association_name, options = {})
        name        = association_name.to_s.singularize
        klass       = (options[:class_name]  || name.capitalize).constantize
        owner_name  = options[:inverse]      || self.to_s.split('::').last.underscore
        foreign_key = (options[:foreign_key] || "#{owner_name}_id").to_s
        local_key   = (options[:local_key]   || "#{name}_id").to_s

        raise TypeError.new("Missing 'number' field in table #{klass.table_name}.") unless klass.column_names.include?('number')
        raise TypeError.new("Missing '#{foreign_key}' in table #{klass.table_name}.") unless klass.column_names.include?(foreign_key)

        has_many association_name, :order => 'number DESC', :class_name => klass.to_s, 
                                    :foreign_key => foreign_key, :dependent => :destroy, :autosave => true
        validate      :"validate_#{name}"
        after_create  :"save_#{name}_after_create"
        before_update :"save_#{name}_before_update"

        include module_for_multiple(name, klass, owner_name, foreign_key, local_key, association_name)
        klass.belongs_to owner_name, :class_name => self.to_s
      end

      protected
        def module_for_multiple(name, klass, owner_name, foreign_key, local_key, association_name)

          # Eval is ugly, but it's the fastest solution I know of
          line = __LINE__
          definitions = <<-EOF
            def #{name}                                     # def version
              @#{name} ||= begin                            #   @version ||= begin
                if v_id = #{local_key}                      #     if v_id = version_id
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
                return true unless @#{name}                 #   return true unless @version
                if @#{name}.marked_for_destruction?         #   if @version.marked_for_destruction?
                  if @#{name}.destroy                       #     if @version.destroy
                    set_current_#{name}_before_update       #       set_current_version_before_update
                    return true                             #       return true
                  else                                      #     else
                    return false                            #       return false
                  end                                       #     end
                end                                         #   end
                @#{name}.properties_will_change!
                return true if !@#{name}.changed?           #   return true if !@version.changed?
                @#{name}.#{foreign_key} = self[:id]         #   @version.owner_id = self[:id]
                if !@#{name}.save(:validate =>false)        #   if !@version.save(:validate=>false)
                  merge_multi_errors('#{name}', @#{name})   #     merge_multi_errors('version', @version)
                  false                                     #     false
                else                                        #   else
                  set_current_#{name}_before_update         #     set_current_version_before_update
                  true                                      #     true
                end                                         #   end
              end                                           # end
                                                            #
              def save_#{name}_after_create                 # def save_version_after_create
                @#{name}.#{foreign_key} = self[:id]         #   version.owner_id = self[:id]
                if !@#{name}.save(:validate=>false)         #   if !@version.save(:validate=>false)
                  merge_multi_errors('#{name}', @#{name})   #     merge_multi_errors('version', @version)
                  self[:id]   = nil
                  @new_record = true
                  raise ActiveRecord::Rollback              #   raise ActiveRecord::Rollback
                else                                        #   else
                  set_current_#{name}_after_create          #     set_current_version_after_create
                end                                         #   end
                true                                        #   true
              end                                           # end


              # This method is triggered when the version is saved, but before the
              # master record is updated. This method is usually overwritten
              # in the class.
              def set_current_#{name}_before_update         # def set_current_version_before_update
                if @#{name}.marked_for_destruction?         #   if @version.marked_for_destruction?
                  if last = #{association_name}.last        #     if last = versions.last
                    self[:#{local_key}] = last.id           #       self[:version_id] = versions.last.id
                  else                                      #     else
                    self[:#{local_key}] = nil               #       self[:version_id] = nil
                  end                                       #     end
                  @#{name} = nil                            #     @version = nil
                else                                        #   else
                  self[:#{local_key}] = @#{name}.id         #     self[:version_id] = @version.id
                end                                         #   end
              end                                           # end

              # This method is triggered when the version is saved, after the
              # master record has been created. This method is usually overwriten
              # in the class.
              def set_current_#{name}_after_create          # def set_current_version_after_create
                # raw SQL to skip callbacks and validtions  #
                conn = self.class.connection                #   conn = self.class.connection
                # conn.execute("UPDATE pages SET \#{conn.quote_column_name("version_id")} = \#{conn.quote(@version.id)} WHERE id = \#{conn.quote(self.id)}")
                conn.execute(
                  "UPDATE \#{self.class.table_name} " +
                  "SET \#{conn.quote_column_name("#{local_key}")} = \#{conn.quote(@#{name}.id)} " +
                  "WHERE id = \#{conn.quote(self.id)}"
                )
                self[:#{local_key}] = @#{name}.id           #   self[:version_id] = @version.id
                changed_attributes.clear                    #   changed_attributes.clear
              end                                           # end
          EOF

          methods_module = Module.new
          methods_module.class_eval(definitions, __FILE__, line + 2)
          methods_module
        end # module_for_multiple
    end # ClassMethods

    private

      def merge_multi_errors(name, model)
        model.errors.each do |attribute, message|
          attribute = "#{name}_#{attribute}"
          errors.add(attribute, message) unless errors[attribute] # FIXME: rails 3: if errors[attribute].empty?
        end
      end
  end # Multi
end # Versions
