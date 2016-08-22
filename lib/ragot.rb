module Ragot

  def self.included(klass)
    klass.extend Spread
  end

  def env
    @env ||= 'development'
  end

  def env=(env)
    @env = env.to_s
  end

  def about(*_, &block)
    declaration = Declaration.new _.shift
    _.any? ? declaration.ragot(*_, &block) : declaration.instance_exec(&block)
  end

  module_function :env
  module_function :env=
  module_function :about

  module Spread

    FAILSAFE = { 'demo' => true, 'production' => true }
    MESSAGE = {
      before: "Entered %s, with params '%s', at %s .%s",
      after: "`%s` called, with params : '%s'. Got '%s' as result, at %s .%s"
    }

    HOOK = ->(hook, meth, result, *_) {
      time = [Time.now].tap { |t| t << t.first.to_f.to_s.split('.').last }
      msg = MESSAGE[hook] % [meth, _.to_s, result, *time].compact
      respond_to?(:tell) ? tell(msg) : puts(msg)
    }

    EXEC_HOOK = ->(failsafe, code, *params) {
      begin
        instance_exec *params, &code
      rescue => e
        failsafe ? nil : raise(e)
      end
    }

    def ragot(method, options={}, &block)
      block ||= ->(result, *_) { instance_exec method, result, *_, &TALK }
      __make_ragot method, block, { failsafe: FAILSAFE[Ragot.env] }.merge(options)
    end

    def initialize(klass)
      @klass = klass
    end

        r
      end
    end

    def ragot(meth, options={}, &block)
      options = { hook: :after, failsafe: FAILSAFE[Ragot.env] }.merge(options)
      block ||= ->(result, *_) { instance_exec options[:hook], meth, result, *_, &HOOK }

      __incept_ragot meth, block, options
    rescue => e
      ((@ragots ||= {})[meth.to_sym] ||= []) << [ meth, block, options ]
    end

    private

    def __incept_ragot(meth, blk, options)
      return unless Array(options[:env]).empty? ||
        Array(options[:env]).map(&:to_s).include?(Ragot.env)

      f = options[:failsafe]
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
