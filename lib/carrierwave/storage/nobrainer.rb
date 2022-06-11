# frozen_string_literal: true

module CarrierWave
  module Storage
    class NoBrainer < Abstract
      ##
      # Store a file
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::Storage::NoBrainer::File] the stored file
      #
      def store!(file)
        f = CarrierWave::Storage::NoBrainer::File.new(uploader, self, uploader.store_path)
        f.store(file)
        f
      end

      ##
      # Retrieve a file
      #
      # === Parameters
      #
      # [identifier (String)] unique identifier for file
      #
      # === Returns
      #
      # [CarrierWave::Storage::NoBrainer::File] the stored file
      #
      def retrieve!(identifier)
        CarrierWave::Storage::NoBrainer::File.new(uploader, self, uploader.store_path(identifier))
      end

      ##
      # Stores given file to cache directory.
      #
      # === Parameters
      #
      # [new_file (File, IOString, Tempfile)] any kind of file object
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def cache!(new_file)
        f = CarrierWave::Storage::NoBrainer::File.new(uploader, self, uploader.cache_path)
        f.store(new_file)
        f
      end

      ##
      # Retrieves the file with the given cache_name from the cache.
      #
      # === Parameters
      #
      # [cache_name (String)] uniquely identifies a cache file
      #
      # === Raises
      #
      # [CarrierWave::InvalidParameter] if the cache_name is incorrectly formatted.
      #
      def retrieve_from_cache!(identifier)
        CarrierWave::Storage::NoBrainer::File.new(uploader, self, uploader.cache_path(identifier))
      end

      ##
      # Deletes a cache dir
      #
      def delete_dir!(path)
        # do nothing, because there's no such things as 'empty directory'
      end

      def clean_cache!(seconds)
        path_regex = %r{#{Regexp.escape(uploader.cache_dir)}/\d+-\d+-\d+-\d+/.+}

        ::NoBrainer::FileCache.where(
          path: path_regex
        ).pluck(:path).without_ordering.raw.to_a.each do |doc|
          matched = doc['path'].match(/(\d+)-\d+-\d+-\d+/)

          next unless matched
          next unless Time.at(matched[1].to_i) < (Time.now.utc - seconds)

          ::NoBrainer::FileCache.where(path: doc['path']).first.delete
        end
      end

      class File
        ##
        # Current local path to file
        #
        # === Returns
        #
        # [String] a path to file
        #
        attr_reader :path

        ##
        # Lookup value for file content-type header
        #
        # === Returns
        #
        # [String] value of content-type
        #
        def content_type
          @content_type || file.try(:content_type)
        end

        ##
        # Removes the file from the filesystem.
        #
        def delete
          criteria = storage_place_from(path).where(path: path).without_ordering

          return unless criteria.present?

          criteria.first.delete

          @content_type = nil
          @file = nil
          @path = nil
        end

        ##
        # lookup file
        #
        # === Returns
        #
        # [NoBrainer::Document] file data from RethinkDB
        #
        def file
          return nil unless path

          storage_place_from(path).where(path: path).without_ordering.first
        end

        ##
        # Return file name, if available
        #
        # === Returns
        #
        # [String] file name
        #   or
        # [NilClass] no file name available
        #
        def filename
          ::File.basename(file.path)
        end

        def initialize(uploader, base, path)
          @uploader, @base, @path, @content_type = uploader, base, path, nil
        end

        ##
        # Read content of file from service
        #
        # === Returns
        #
        # [String] contents of file
        def read
          file && file.body
        end

        ##
        # Return size of file body
        #
        # === Returns
        #
        # [Integer] size of file body
        #
        def size
          file.nil? ? 0 : file.body.length
        end

        ##
        # Check if the file exists on the remote service
        #
        # === Returns
        #
        # [Boolean] true if file exists or false
        def exists?
          !!file
        end

        ##
        # Write file to service
        #
        # === Returns
        #
        # [Boolean] true on success or raises error
        def store(new_file)
          nobrainer_file = new_file.file.body if new_file.is_a?(self.class)
          nobrainer_file ||= new_file.to_file.read

          @content_type ||= new_file.content_type

          @file = storage_place_for(new_file).where(path: path).first_or_create(
            content_type: new_file.content_type,
            body: nobrainer_file
          )

          @file.save!

          true
        end

        private

        def storage_place_for(file)
          return ::NoBrainer::FileStorage if file.is_a?(self.class)

          ::NoBrainer::FileCache
        end

        def storage_place_from(path)
          return ::NoBrainer::FileCache if path.start_with?(@uploader.cache_dir)

          ::NoBrainer::FileStorage
        end
      end
    end
  end
end

# Adds the `:nobrainer` storage engine
CarrierWave::Uploader::Base.storage_engines[:nobrainer] = 'CarrierWave::Storage::NoBrainer'
