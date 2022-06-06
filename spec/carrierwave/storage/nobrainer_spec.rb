# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe CarrierWave::Storage::NoBrainer do
  let(:filename) { '1.txt' }
  let(:filepath) { File.open("#{SPEC_ROOT}/tmp/files/#{filename}") }
  let(:filename2) { '2.txt' }
  let(:filepath2) { File.open("#{SPEC_ROOT}/tmp/files/#{filename2}") }

  before do
    load_simple_document
    load_simple_document_with_nobrainer_storage

    Model.mount_uploader :file, Uploader
  end

  describe 'storage: nobrainer with a new document without a file' do
    it 'saves' do
      expect(Model.new.save).to be_truthy
    end
  end

  describe 'storage: :nobrainer with a new document with a file' do
    let(:new_doc) do
      Model.new.tap do |doc|
        doc.file = filepath
        doc.save!
      end
    end

    it 'saves' do
      expect(new_doc.valid?).to be_truthy
    end

    it 'creates a NoBrainer::FileStorage entry' do
      expect(new_doc.file).to be_present
      expect(NoBrainer::FileStorage.count).to eql(1)
    end

    it 'stores the file at the given path' do
      expect(new_doc.file.current_path).to eql("uploads/#{filename}")
    end

    it 'stores the filename' do
      expect(new_doc.file.filename).to eql(filename)
    end

    it 'stores the filename also at uploader level' do
      expect(new_doc.file.file.filename).to eql(filename)
    end

    it 'retrives the file' do
      expect(new_doc.file.read).to eql(File.read(filepath))
    end

    it 'stores the file content type' do
      expect(new_doc.file.content_type).to eql('text/plain')
    end

    it 'retrives the file size' do
      expect(new_doc.file.size).to eql(6)
    end
  end

  describe 'storage: :nobrainer deleting the file from a new document' do
    let(:new_doc) { Model.new }

    before do
      new_doc.file = filepath
      new_doc.save!

      new_doc.file = nil
      new_doc.save!
    end

    it 'deletes the file' do
      expect(new_doc.file.file).to be_nil
    end

    it 'returns an empty path' do
      expect(new_doc.file.current_path).to be_nil
    end

    it 'returns a nil as file' do
      expect(new_doc.file.read).to be_nil
    end

    it 'returns an empty content type' do
      expect(new_doc.file.content_type).to be_nil
    end

    it 'returns a size of zero' do
      expect(new_doc.file.size).to be_zero
    end
  end

  describe 'storage: :nobrainer replacing the file from a new document' do
    let(:new_doc) { Model.new }

    before do
      new_doc.file = filepath
      new_doc.save!

      new_doc.file = filepath2
      new_doc.save!
    end

    it 'saves' do
      expect(new_doc.valid?).to be_truthy
    end

    it 'creates a NoBrainer::FileStorage entry' do
      expect(new_doc.file.file.exists?).to be_truthy
      expect(NoBrainer::FileStorage.count).to eql(1)
    end

    it 'stores the file at the given path' do
      expect(new_doc.file.current_path).to eql("uploads/#{filename2}")
    end

    it 'stores the filename' do
      expect(new_doc.file.filename).to eql(filename2)
    end

    it 'stores the filename also at uploader level' do
      expect(new_doc.file.file.filename).to eql(filename2)
    end

    it 'retrives the file' do
      expect(new_doc.file.read).to eql(File.read(filepath2))
    end

    it 'stores the file content type' do
      expect(new_doc.file.content_type).to eql('text/plain')
    end

    it 'retrives the file size' do
      expect(new_doc.file.size).to eql(6)
    end
  end

  describe 'storage: nobrainer with an existing document with a file' do
    let(:doc) { Model.last }

    before { Model.create!(file: filepath) }

    it 'has a attached file' do
      expect(doc.file.file.exists?).to be_truthy
    end

    it 'retrives the file path from RethinkDB' do
      expect(doc.file.current_path).to eql("uploads/#{filename}")
    end

    # This test fails because `doc.file.filename` return nil while it should
    # return the filename.
    xit 'stores the filename' do
      expect(doc.file.filename).to eql(filename)
    end

    it 'stores the filename also at uploader level' do
      expect(doc.file.file.filename).to eql(filename)
    end

    it 'retrives the file from RethinkDB' do
      expect(doc.file.read).to eql(File.read(filepath))
    end

    it 'retrives the file content type' do
      expect(doc.file.content_type).to eql('text/plain')
    end

    it 'retrives the file size' do
      expect(doc.file.size).to eql(6)
    end
  end

  describe 'storage: :nobrainer deleting the file from an existing document' do
    let(:doc) do
      Model.last.tap do |doc|
        doc.file = nil
        doc.save!
      end
    end

    before do
      doc = Model.create!
      doc.file = filepath
      doc.save!
    end

    it 'deletes the file' do
      expect(doc.file.file).to be_nil
    end

    it 'returns an empty path' do
      expect(doc.file.current_path).to be_nil
    end

    it 'stores the filename' do
      expect(doc.file.filename).to be_nil
    end

    it 'returns a nil as file' do
      expect(doc.file.read).to be_nil
    end

    it 'returns an empty content type' do
      expect(doc.file.content_type).to be_nil
    end

    it 'returns a size of zero' do
      expect(doc.file.size).to be_zero
    end
  end

  describe 'storage: nobrainer replacing the file from an existing document' do
    let(:doc) do
      Model.last.tap do |doc|
        doc.file = filepath2
        doc.save!
      end
    end

    before { Model.create!(file: filepath) }

    it 'has a attached file' do
      expect(doc.file).to be_present
    end

    it 'retrives the file path from RethinkDB' do
      expect(doc.file.current_path).to eql("uploads/#{filename2}")
    end

    it 'retrives the file from RethinkDB' do
      expect(doc.file.read).to eql(File.read(filepath2))
    end

    it 'stores the filename' do
      expect(doc.file.filename).to eql(filename2)
    end

    it 'stores the filename also at uploader level' do
      expect(doc.file.file.filename).to eql(filename2)
    end

    it 'retrives the file content type' do
      expect(doc.file.content_type).to eql('text/plain')
    end

    it 'retrives the file size' do
      expect(doc.file.size).to eql(6)
    end
  end

  describe 'clean_cache!' do
    let(:cache) do
      ::NoBrainer::FileStorage.where(
        path: /^#{Regexp.escape(CACHE_DIR)}.*/
      ).to_a
    end

    before do
      Model.create!(file: filepath)
      Uploader.clean_cached_files!
    end

    it 'clears the cached files' do
      expect(cache).to be_empty
    end
  end

  describe 'uploading file through a mount_uploader using storage nobrainer' do
    let(:new_doc) { Model.new }

    context 'when uploading a file' do
      before { new_doc.file = filepath }

      it 'saves' do
        expect(new_doc.save).to be_truthy
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
