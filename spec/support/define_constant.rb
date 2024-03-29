# frozen_string_literal: true

require 'set'

module DefineConstantMacros
  def define_module(mod_name, &block)
    mod = Module.new
    mod.class_eval(&block) if block_given?
    Object.const_set(mod_name, mod)
  end

  def define_class(class_name, base = Object, &block)
    name = class_name.to_s.split('::')
    mod, klass_name = if name.length > 1
                        module_name = name.first
                        klass_name = name.last

                        if Object.const_defined?(module_name)
                          mod = Object.const_get(module_name)
                        else
                          mod = Module.new
                          Object.const_set(module_name, mod)
                        end

                        [mod, klass_name]
                      else
                        [Object, class_name]
                      end
    klass = Class.new(base)
    mod.const_set(klass_name, klass)

    @defined_constants[mod] ||= []
    @defined_constants[mod] << klass_name

    klass.class_eval(&block) if block_given?

    klass
  end

  RSpec.configure { |config| config.include self }
end

RSpec.configure do |config|
  config.before do
    @defined_constants = {}
  end

  config.after do
    @defined_constants.each do |base, class_names|
      class_names.each do |class_name|
        base.send(:remove_const, class_name)
      end
    end
  end
end
