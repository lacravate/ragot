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
      @klass, @ragots, @i = klass, {}, { klass => {}, klass.singleton_class => {} }
    end

    def trigger(meth)
      @ragots[meth] && @ragots[meth].shift(@ragots[meth].size).each do |r|
        __incept_ragot *r
      end
    end

    def ragot(meth, options={}, &block)
      __incept_ragot(meth.to_sym, block, options) ||
        (@ragots[meth.to_sym] ||= []).push([meth.to_sym, block, options])
    end

    private

    FAILSAFE = { 'demo' => true, 'production' => true }
    MESSAGE = {
      before: "Entered %s, with params '%s',%s at %s .%s",
      after: "`%s` called, with params : '%s'. Got '%s' as result, at %s .%s"
    }

    def self.exec_hook(ragotee, failsafe, code, *result_and_params)
      ragotee.instance_exec *result_and_params, &code
    rescue => e
      failsafe ? nil : raise(e)
    end

    def __incept_ragot(meth, blk, options)
      o = { hook: :after, failsafe: FAILSAFE[Ragot.env], env: Ragot.env }.merge(options)
      k = o[:class] ? @klass.singleton_class : @klass
      @i[k][meth] ||= { before: [], after: [], stamp: [] }

      return unless Array(o[:env]).map(&:to_s).include? Ragot.env
      return unless (k.instance_methods + k.private_instance_methods).include? meth.to_sym

      @i[k][meth][ :stamp ] << [ o[:failsafe], default_hook(meth, :before) ] if o[:stamp]
      @i[k][meth][o[:hook]] << [ o[:failsafe], blk || default_hook(meth,  o[:hook]) ]
      @i[k][meth][:alias] ||= redefine k, meth, @i[k][meth]
    end

        r
      }

    end

  end

end
