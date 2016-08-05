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
    TALK = ->(method, result, *_) { tell "`#{method}` called, with params : '#{_}'. Got '#{result}' as result" }
    STAMP = ->(method) { tell "entered #{method} at #{Time.now.to_f}" }
    EXECUTE_HOOKS = ->(failsafe, code, *params) {
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

    private

    def __make_ragot(method, talk, options)
      return unless Array(options[:env]).empty? || Array(options[:env]).map(&:to_s).include?(Ragot.env)

      k = options[:class] ? klass.singleton_class : klass
      k.send :alias_method, "__ragot_inception_#{method}", method
      k.send :define_method, method, ->(*_, &b) do
        @need_tell ||= respond_to?(:tell, true) || !!self.class.send(:alias_method, :tell, :puts)

        instance_exec options[:failsafe], STAMP, method, &EXECUTE_HOOKS if options[:stamp]
        r = send "__ragot_inception_#{method}", *_, &b
        instance_exec options[:failsafe], talk, r, *_, &EXECUTE_HOOKS

        r
      end
    end

  end

  class Declaration

    include Spread

    def initialize(klass=nil)
      @klass = klass
    end

    def klass
      @klass || self.class
    end

  end

end
