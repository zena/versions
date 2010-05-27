require 'digest'

module Versions
  class SharedAttachment < ::ActiveRecord::Base
    set_table_name 'attachments'
    after_destroy :destroy_file
    after_save    :write_file

    def self.filepath(id, filename)
      digest = ::Digest::SHA1.hexdigest(id.to_s)
      "#{digest[0..0]}/#{digest[1..1]}/#{filename}"
    end

    def unlink(model)
      link_count = model.class.count(:conditions => ["attachment_id = ? AND id != ?", self.id, model.id])
      if link_count == 0
        destroy
      end
    end

    def file=(file)
      @file = file
      self.filename = get_filename(file)
    end

    def filename=(name)
      fname = name.gsub(/[^a-zA-Z\-_0-9\.]/,'')
      if fname[0..0] == '.'
        # Forbid names starting with a dot
        fname = Digest::SHA1.hexdigest(Time.now.to_i.to_s)[0..6]
      end
      self[:filename] = fname
    end

    def file
      File.new(filepath)
    end

    def filepath
      @filepath ||= self.class.filepath(self[:id], filename)
    end

    private
      def write_file
        after_commit do
          make_file(filepath, @file)
        end
      end

      def destroy_file
        after_commit do
          remove_file
        end
      end

      def make_file(path, data)
        FileUtils::mkpath(File.dirname(path)) unless File.exist?(File.dirname(path))
        if data.respond_to?(:rewind)
          data.rewind

          File.open(path, "wb") do |file|
            while buffer = data.read(2_024_000)
              file.syswrite(buffer)
            end
          end
        else
          File.open(path, "wb") do |file|
            file.syswrite(data.read)
          end
        end
      end

      def remove_file
        FileUtils.rm(filepath)
      end

      def get_filename(file)
        file.original_filename
      end
  end # SharedAttachment
end # Versions
