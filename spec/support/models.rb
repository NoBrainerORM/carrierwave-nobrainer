module ModelsHelper
  def load_simple_document
    define_class :Model do
      include NoBrainer::Document
    end
  end

  RSpec.configure { |config| config.include self }
end
