# frozen_string_literal: true

module ModelsHelper
  def load_simple_document
    define_class :Model do
      include NoBrainer::Document
    end
  end

  def load_simple_document_with_nobrainer_storage
    define_class :Uploader, CarrierWave::Uploader::Base do
      storage :nobrainer
    end
  end

  RSpec.configure { |config| config.include self }
end
