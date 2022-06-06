# frozen_string_literal: true

require 'spec_helper'

describe CarrierWave::NoBrainer do
  before { load_simple_document }

  let(:src_file1) { File.open("#{SPEC_ROOT}/tmp/files/1.txt") }
  let(:src_file2) { File.open("#{SPEC_ROOT}/tmp/files/2.txt") }

  let(:src_file)  { src_file1 }
  let(:filename) { File.basename(src_file) }

  describe 'mount_uploader' do
    context 'when using vanilla options' do
      before { Model.mount_uploader :file }

      it 'mount the file' do
        Model.create!(file: src_file)
        expect(Model.raw.first['file']).to eql(filename)
        expect(File.exist?(Model.first.file.path)).to be_truthy
      end
    end

    context 'when validating processing' do
      before do
        Model.mount_uploader :file do
          process :raise_error
          def raise_error
            raise CarrierWave::ProcessingError, 'Oops'
          end
        end
      end

      it 'should make the record invalid when a processing error occurs' do
        m = Model.new(file: src_file1)
        expect(m.valid?).to be_falsy
        expect(m.errors[:file]).to eql(['Oops'])
      end
    end

    context 'when file is changing' do
      before { Model.mount_uploader :file }

      it 'detects the change' do
        m = Model.new
        m.file = src_file1
        m.save

        path1 = m.file.path
        expect(File.exist?(path1)).to be_truthy

        m.update!(file: src_file2)

        expect(File.exist?(path1)).to be_falsy
      end

      it 'removes the file' do
        m = Model.create!(file: src_file)
        path1 = m.file.path
        expect(File.exist?(path1)).to be_truthy
        m.remove_file!
        expect(File.exist?(path1)).to be_falsy
      end
    end

    context 'when destorying the model' do
      before { Model.mount_uploader :file }

      it 'removes the files' do
        m = Model.create!(file: src_file)
        path1 = m.file.path
        expect(File.exist?(path1)).to be_truthy
        m.destroy
        expect(File.exist?(path1)).to be_falsy
      end
    end
  end

  context 'when the file is not changing' do
    before { Model.mount_uploader :file }

    it 'should not detect the change' do
      Model.create!(file: src_file)

      m = Model.first
      m.file
      expect(m.changes).to eql({})
    end
  end

  context 'when using :filename options' do
    let(:filename) { 'stuff.txt' }
    before { Model.mount_uploader :file, nil, filename: filename }

    it 'mount the file' do
      Model.create!(file: src_file)

      expect(Model.raw.first['file']).to be_nil

      f = Model.first.file
      expect(f.file).to be_present
      expect(f.filename).to eql(filename)
      f.retrieve_from_store!(f.filename)
      f.cache!
      expect(File.read(f.path)).to eql(src_file.read)
    end
  end

  context 'when using mount_uploaders' do
    before { Model.mount_uploaders :files }

    it 'stores files' do
      Model.create!(files: [src_file1, src_file2])
      files = Model.first.files
      expect(files.map(&:read)).to eql([src_file1, src_file2].map(&:read))

      Model.first.update!(files: [src_file1])

      expect(File.exist?(Model.first.files.first.path)).to be_truthy
    end

    it 'remove files with = []' do
      Model.create!(files: [src_file1])
      Model.first.update!(files: [])
      expect(Model.first.files).to eql([])
    end

    context 'when the file is not changing' do
      it 'should not detect the change' do
        Model.create!(files: [src_file1, src_file2])
        m = Model.first
        m.files
        expect(m.changes).to eql({})
      end
    end
  end
end
