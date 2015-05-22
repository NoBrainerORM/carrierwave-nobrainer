require 'nobrainer'
require 'carrierwave'
require 'carrierwave/validations/active_model'

module CarrierWave
  module NoBrainer
    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      if options[:filename]
        super(column, uploader, options.merge(:store_filename => false)) do
          define_method(:filename) { options[:filename] }
        end
      else
        super
      end

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def remote_#{column}_url=(url)
          column = _mounter(:#{column}).serialization_column
          attribute_may_change("#{column}")
          super
        end
      RUBY
    end

    ##
    # See +CarrierWave::Mount#mount_uploaders+ for documentation
    #
    def mount_uploaders(column, uploader=nil, options={}, &block)
      super

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def remote_#{column}_urls=(url)
          column = _mounter(:#{column}).serialization_column
          attribute_may_change("#{column}")
          super
        end
      RUBY
    end

    private

    def mount_base(column, uploader=nil, options={}, &block)
      super

      if options[:store_filename] == false
        class_eval <<-RUBY, __FILE__, __LINE__+1
          def write_#{column}_identifier; end
        RUBY
      else
        field options[:mount_on] || column
      end

      alias_method :read_uploader, :_read_attribute
      alias_method :write_uploader, :_write_attribute

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
      validates_download_of column if uploader_option(column.to_sym, :validate_download)

      before_save :"write_#{column}_identifier"
      before_save :"store_#{column}!"

      after_destroy :"remove_#{column}!"
      after_update :"mark_remove_#{column}_false"

      before_save :"store_previous_changes_for_#{column}"
      after_update :"remove_previously_stored_#{column}"

      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}=(new_file)
          column = _mounter(:#{column}).serialization_column
          attribute_may_change(column)
          super
        end

        def remove_#{column}=(value)
          attribute_may_change("#{column}")
          super
        end

        def remove_#{column}!
          super
          self.remove_#{column} = true
          write_#{column}_identifier unless destroyed?
        end

        def store_previous_changes_for_#{column}
          @_previous_changes_for_#{column} = changes[_mounter(:#{column}).serialization_column]
        end

        # Reset cached mounter on record reload
        def reload(*)
          @_mounters = nil
          super
        end

        # Reset cached mounter on record dup
        def initialize_dup(other)
          @_mounters = nil
          super
        end
      RUBY
    end
  end
end

module NoBrainer::Document::ClassMethods
  include CarrierWave::NoBrainer
end
