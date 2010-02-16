require 'versions/shared_attachment'

module Versions

  # The attachement module provides shared file attachments to a class with a copy-on-write
  # pattern.
  # Basically the module provides 'file=' and 'file' methods.
  # The file is shared between versions if it is not changed. The Attachment only stores a
  # reference to the file which is saved in the filesystem.
  module Attachment

    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def store_attachments_in(accessor, options = {})
        attachment_class = options[:attachment_class] || '::Versions::SharedAttachment'

        if accessor.nil? || accessor == self
          belongs_to :attachment,
                     :class_name  => attachment_class,
                     :foreign_key => 'attachment_id'
          include Owner
        else
          klass = (options[:class_name] || accessor.to_s.capitalize).constantize
          klass.class_eval do
            belongs_to :attachment,
                       :class_name  => attachment_class,
                       :foreign_key => 'attachment_id'
            include Owner
          end

          line = __LINE__
          definitions = <<-EOF
            def file=(file)
              #{accessor}.file = file
            end

            def file
              #{accessor}.file
            end
          EOF

          methods_module = Module.new
          methods_module.class_eval(definitions, __FILE__, line + 2)
          include methods_module
        end

      end
    end

    module Owner
      def self.included(base)
        base.class_eval do
          before_create  :save_attachment
          before_update  :attachment_before_update
          before_destroy :attachment_before_destroy
        end
      end

      def file=(file)
        if attachment
          @attachment_to_unlink = self.attachment
          self.attachment = nil
        end
        @attachment_need_save = true
        self.build_attachment(:file => file)
      end

      def file
        attachment ? attachment.file : nil
      end

      def filepath
        attachment ? attachment.filepath : nil
      end

      private
        def save_attachment
          if @attachment_need_save
            @attachment_need_save = nil
            attachment.save
          else
            true
          end
        end

        def attachment_before_update
          if @attachment_to_unlink
            @attachment_to_unlink.unlink(self)
            @attachment_to_unlink = nil
          end
          save_attachment
        end

        def attachment_before_destroy
          if attachment = self.attachment
            attachment.unlink(self)
          else
            true
          end
        end
    end # Owner
  end # Attachment
end # Versions