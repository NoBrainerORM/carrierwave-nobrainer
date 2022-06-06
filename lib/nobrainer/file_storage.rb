# frozen_string_literal: true

module NoBrainer
  #
  # CarrierWave store for uploaded files in a table where all uploaded files
  # will remain until users request to delete them.
  # Querying this table will be slower than the NoBrainer::FileCahe one.
  #
  class FileStorage
    include NoBrainer::Document

    table_config name: 'nobrainer_storages'

    field :content_type, type: String
    field :body, type: Binary
    field :path, type: String, primary_key: true
  end
end

NoBrainer::Document::Core._all << NoBrainer::FileStorage
