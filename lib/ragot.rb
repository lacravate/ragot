module Ragot

  def self.included(klass)
    klass.extend RagotInside
  end

  def env
    @env ||= 'development'
  end

  def env=(env)
    @env = env.to_s
  end

  def about(klass, *_, &block)
    Declaration.for(klass).send (_.empty? ? :instance_exec : :ragot), *_, &block
  end

  module_function :about, :env, :env=

  module RagotInside

    def self.extended(klass)
      unless klass.respond_to?(:after, true) || klass.respond_to?(:before, true)
        klass.singleton_class.send :alias_method, :before, :declare_ragot
        klass.singleton_class.send :alias_method, :after, :declare_ragot
      end
    end

    def singleton_method_added(meth)
      if method(meth).owner != Ragot::RagotInside && %i|before after|.include?(meth)
        singleton_class.send :remove_method, (%i|before after| - [meth]).first
      end
    end

    def method_added(meth)
      Declaration.for(self).trigger meth
    end

    def declare_ragot(meth,  options={}, &block)
      hook = __callee__.to_s.split('_').last.to_sym
      Declaration.for(self).ragot meth, options.merge(hook: hook), &block
    end

    alias_method :ragot_after, :declare_ragot
    alias_method :ragot_before, :declare_ragot
    private :declare_ragot

  end

  class Declaration

    def self.for(klass)
      (@collection ||= {})[klass] ||= new klass
    end

    def initialize(klass)
      @klass = klass
    end

    def trigger(meth)
      Array(@ragots && @ragots[meth.to_sym]).each do |r|
        __incept_ragot *@ragots[meth.to_sym].delete(r)
      end
    end

    def ragot(meth, options={}, &block)
      __incept_ragot meth, block, options
    rescue => e
      ((@ragots ||= {})[meth.to_sym] ||= []) << [ meth, block, options ]
    end

    private

    FAILSAFE = { 'demo' => true, 'production' => true }
    MESSAGE = {
      before: "Entered %s, with params '%s',%s at %s .%s",
      after: "`%s` called, with params : '%s'. Got '%s' as result, at %s .%s"
    }

    DEFAULT_HOOK = ->(hook, meth, result, *_) {
      time = [Time.now].tap { |t| t << t.first.to_f.to_s.split('.').last }
      ragot_talk MESSAGE[hook] % [meth, _.to_s, result, *time]
    }

    def self.exec_hook(ragoted, failsafe, code, *result_and_params)
      ragoted.instance_exec *result_and_params, &code
    rescue => e
      failsafe ? nil : raise(e)
    end

    def __incept_ragot(meth, blk, options)
      o = { hook: :after, failsafe: FAILSAFE[Ragot.env], env: Ragot.env }.merge(options)

      return unless Array(o[:env]).map(&:to_s).include? Ragot.env

      k = o[:class] ? @klass.singleton_class : @klass
      aka = "__ragot_inception_#{meth}_#{Time.now.to_f.to_s.sub('.', '_')}"
      k = options[:class] ? @klass.singleton_class : @klass
      k.send :alias_method, aka, meth
      k.send :define_method, meth, ->(*_, &b) {
        instance_exec f, HOOK, :before, meth, nil, *_, &EXEC_HOOK if options[:stamp]
        instance_exec f, blk, meth, *_, &EXEC_HOOK if options[:hook] == :before
        r = send aka, *_, &b
        instance_exec f, blk, r, *_, &EXEC_HOOK if options[:hook] == :after

        r
      }
    end

  end

end
