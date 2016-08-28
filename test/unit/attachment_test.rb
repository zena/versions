# encoding: utf-8
require 'helper'

class AttachmentTest < Test::Unit::TestCase
  @@attachments_dir = (Pathname(__FILE__).dirname + 'tmp').expand_path

  Attachment = Class.new(Versions::SharedAttachment) do
    def filepath
      File.join(@@attachments_dir, super)
    end
  end

  # Mock a version class with shared attachments (between versions of the same document)
  class Version < ActiveRecord::Base
    include Versions::Auto
  end

  # Mock a document class with many versions
  class Document < ActiveRecord::Base
    include Versions::Multi
    has_multiple :versions, :class_name => 'AttachmentTest::Version', :inverse => 'node'

    include Versions::Attachment
    store_attachments_in :version, :class_name => 'AttachmentTest::Version', :attachment_class => 'AttachmentTest::Attachment'

    self.table_name = :pages

    def title
      version.title
    end

    def title=(t)
      version.title = t
    end
  end


  def setup
    FileUtils.rmtree(@@attachments_dir)
  end

  context 'When creating a new owner' do
    setup do
      @owner = Version.create(:file => uploaded_jpg('bird.jpg'))
    end

    should 'store file in the filesystem' do
      assert File.exist?(@owner.filepath)
      assert_equal uploaded_jpg('bird.jpg').read, File.read(@owner.filepath)
    end

    should 'restore the filepath from the database' do
      attachment = Attachment.find(@owner.attachment_id)
      assert_equal @owner.filepath, attachment.filepath
    end

    should 'restore the file with the database' do
      attachment = Attachment.find(@owner.attachment_id)
      assert_equal uploaded_jpg('bird.jpg').read, attachment.file.read
    end

    should 'rename file on bad original_filename' do
      file = uploaded_jpg('bird.jpg')
      class << file
        def original_filename
          '../../bad.txt'
        end
      end
      owner = Version.create(:file => file)
      assert File.exist?(owner.filepath)
      assert_no_match %r{bird\.jpg}, owner.filepath
      assert_no_match %r{bad\.txt}, owner.filepath
    end
  end

  context 'When the transaction fails' do
    should 'not write file on create' do
      owner    = nil
      filepath = nil
      assert_difference('Attachment.count', 0) do
        Version.transaction do
          owner = Version.create(:file => uploaded_jpg('bird.jpg'))
          filepath = owner.filepath
          assert !File.exist?(filepath)
          raise ActiveRecord::Rollback
        end
      end
      assert !File.exist?(filepath)
    end

    should 'not remove file on destroy' do
      @owner   = Version.create(:file => uploaded_jpg('bird.jpg'))
      filepath = @owner.filepath
      assert File.exist?(filepath)
      assert_difference('Attachment.count', 0) do
        Version.transaction do
          @owner.destroy
          assert File.exist?(filepath)
          raise ActiveRecord::Rollback
        end
      end
      assert File.exist?(filepath)
    end
  end

  context 'On an owner with a file' do
    setup do
      @owner = Version.create(:file => uploaded_jpg('bird.jpg'))
      @owner = Version.find(@owner.id)
      @owner.class_eval do
        def should_clone?
          false
        end
      end
    end

    should 'remove file in the filesystem when updating file' do
      old_filepath = @owner.filepath
      assert_difference('Attachment.count', 0) do # destroy + create
        assert @owner.update_attributes(:file => uploaded_jpg('lake.jpg'))
      end
      assert_not_equal old_filepath, @owner.filepath
      assert File.exist?(@owner.filepath)
      assert_equal uploaded_jpg('lake.jpg').read, File.read(@owner.filepath)
      assert !File.exist?(old_filepath)
    end

    should 'get file when sent :file' do
      assert_equal uploaded_jpg('bird.jpg').read, @owner.file.read
    end

    should 'get file before save when sent :file' do
      @owner = Version.new(:file => uploaded_jpg('bird.jpg'))
      assert_equal uploaded_jpg('bird.jpg').read, @owner.file.read
    end
  end

  context 'Updating document' do
    setup do
      begin
        @doc = Document.create(:title => 'birdy', :file => uploaded_jpg('bird.jpg'))
      rescue => err
        puts err.message
        puts err.backtrace.join("\n")
      end
    end

    # Updating document ...attributes
    context 'attributes' do
      setup do
        assert_difference('Version.count', 1) do
          @doc.update_attributes(:title => 'hopla')
        end
      end

      should 'reuse the same filepath in new versions' do
        filepath = nil
        @doc.versions.each do |version|
          if filepath
            assert_equal filepath, version.filepath
          else
            filepath = version.filepath
          end
        end
      end
    end

    # Updating document ...file
    context 'file' do
      setup do
        assert_difference('Version.count', 1) do
          @doc.update_attributes(:file => uploaded_jpg('lake.jpg'))
        end
      end

      should 'create new filepath' do
        filepath = nil
        @doc.versions.each do |version|
          if filepath
            assert_not_equal filepath, version.filepath
          else
            filepath = version.filepath
          end
        end
      end
    end # Updating document .. file
  end # Updating document

  context 'On a document with many versions' do
    setup do
      assert_difference('Version.count', 2) do
        @doc = Document.create(:title => 'birdy', :file => uploaded_jpg('bird.jpg'))
        @doc.update_attributes(:title => 'Vögel')
        @doc = Document.find(@doc.id)
      end
    end

    context 'removing a version' do

      should 'not remove shared attachment' do
        filepath = @doc.version.filepath

        assert_difference('Version.count', -1) do
          assert_difference('Attachment.count', 0) do
            assert @doc.version.destroy
          end
        end
        assert File.exist?(filepath)
      end
    end

    context 'removing the last version' do

      should 'remove shared attachment' do
        filepath = @doc.version.filepath

        assert_difference('Version.count', -2) do
          assert_difference('Attachment.count', -1) do
            @doc.versions.each do |version|
              assert version.destroy
            end
          end
        end
        assert !File.exist?(filepath)
      end
    end
  end

  context 'A module using attachments without versions' do
    class Doc < ActiveRecord::Base
      self.table_name = :versions
      include Versions::Attachment
      store_attachments_in self, :attachment_class => 'AttachmentTest::Attachment'
    end

    subject do
      Doc.create('file' => uploaded_jpg('bird.jpg'))
    end

    should 'accept files' do
      assert !subject.new_record?
    end

    should 'store file in the filesystem' do
      assert File.exist?(subject.filepath)
      assert_equal uploaded_jpg('bird.jpg').read, File.read(subject.filepath)
    end

    should 'restore the filepath from the database' do
      attachment = Attachment.find(subject.attachment_id)
      assert_equal subject.filepath, attachment.filepath
    end

    should 'remove file in the filesystem when updating file' do
      old_filepath = subject.filepath
      assert_difference('Attachment.count', 0) do # destroy + create
        assert subject.update_attributes(:file => uploaded_jpg('lake.jpg'))
      end
      assert_not_equal old_filepath, subject.filepath
      assert File.exist?(subject.filepath)
      assert_equal uploaded_jpg('lake.jpg').read, File.read(subject.filepath)
      assert !File.exist?(old_filepath)
    end

    should 'create and destroy objects without attachments' do
      assert Doc.create.destroy
    end
  end

  private
    def filepath(attachment_id, filename)
      digest = Digest::SHA1.hexdigest(attachment_id.to_s)
      "#{digest[0..0]}/#{digest[1..1]}/#{filename}"
    end
end