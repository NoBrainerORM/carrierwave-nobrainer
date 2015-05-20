require 'spec_helper'

describe CarrierWave::NoBrainer do
  before do
    define_class :Model do
      include NoBrainer::Document
    end
  end

  let(:src_file1) { File.open("#{SPEC_ROOT}/tmp/files/1.txt") }
  let(:src_file2) { File.open("#{SPEC_ROOT}/tmp/files/2.txt") }

  let(:src_file)  { src_file1 }
  let(:filename) { File.basename(src_file) }

  describe 'mount_uploader' do
    context 'when using vanilla options' do
      before { Model.mount_uploader :file }

      it 'mount the file' do
        Model.create!(:file => src_file)
        Model.raw.first['file'].should == filename
        File.exist?(Model.first.file.path).should == true
      end
    end

    context 'when validating processing' do
      before do
        Model.mount_uploader :file do
          process :raise_error
          def raise_error
            raise CarrierWave::ProcessingError, "Oops"
          end
        end
      end

      it "should make the record invalid when a processing error occurs" do
        m = Model.new(:file => src_file1)
        m.valid?.should == false
        m.errors[:file].should == ['Oops']
      end
    end

    context 'when file is changing' do
      before { Model.mount_uploader :file }

      it 'detects the change' do
        m = Model.new
        m.file = src_file1
        m.save

        path1 = m.file.path
        File.exist?(path1).should == true

        m.file_changed?.should == false
        m.file = src_file2
        m.file_changed?.should == true
        m.save

        File.exist?(path1).should == false
      end

      it 'removes the file' do
        m = Model.create!(:file => src_file)
        path1 = m.file.path
        File.exist?(path1).should == true
        m.remove_file!
        File.exist?(path1).should == false
      end
    end
  end

  context 'when using :filename options' do
    let(:filename) { 'stuff.txt' }
    before { Model.mount_uploader :file, nil, :filename => filename }

    it 'mount the file' do
      Model.create!(:file => src_file)
      Model.raw.first['file'].should == nil
      f = Model.first.file
      f.filename.should == filename
      f.retrieve_from_store!(f.filename)
      f.cache!
      File.open(f.path).read.should == src_file.read
    end
  end

  context 'when using mount_uploaders' do
    before { Model.mount_uploaders :files }

    it 'stores files' do
      Model.create!(:files => [src_file1, src_file2])
      files = Model.first.files
      files.map { |f| f.read }.should == [src_file1, src_file2].map { |f| f.read }
    end
  end
end
