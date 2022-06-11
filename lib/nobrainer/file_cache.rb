# frozen_string_literal: true

module NoBrainer
  #
  # CarrierWave cache storage for uploaded files.
  #
  # This table will contain less documents than NoBrainer::FileStorage and
  # therefore gets quicker query executions.
  #
  class FileCache
    include NoBrainer::Document

    table_config name: 'nobrainer_filecaches'

    field :content_type, type: String
    field :body, type: Binary
    field :path, type: String, primary_key: true
  end
end

NoBrainer::Document::Core._all << NoBrainer::FileCache
