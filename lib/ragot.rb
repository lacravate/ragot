module Ragot

  def self.included(klass)
    klass.extend Spread
  end

  def about(*_, &block)
    d = Declaration.new _.shift

    if _.any?
      d.ragot *_, &block
    else
      d.instance_exec &block
    end

    d.make_ragots
  end

  module_function :about

  module Spread

    def ragot(method, options={}, &block)
      block ||= ->(result, *_) do
        log "#{method} called, with params : #{_}"
        log result
      end

      (@ragots ||= []) << [method, block, options]
    end

    def make_ragots(klass=@klass)
      @ragots.each do |rag|
        method, talk, options = rag

        klass = klass.singleton_class if options[:class]
        stamp = -> { log "entered #{method} at #{Time.now.to_f}" } if options[:stamp]

        klass.send :alias_method, "__loggable_#{method}", method
        klass.send :define_method, method, ->(*_, &b) do
          instance_exec &stamp if stamp rescue nil
          r = send "__loggable_#{method}", *_, &b
          instance_exec r, &talk rescue nil

          r
        end
      end
    end

  end

  class Declaration

    include Spread

    def initialize(klass=nil)
      @klass = klass
    end

  end

end
