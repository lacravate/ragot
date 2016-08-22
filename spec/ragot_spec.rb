require 'json'

class RagotString < String

  module Tell
    def tell(*_)
      (@log ||= []) << _
    end

    def log
      @log
    end
  end

  extend Tell
  include Tell

end

class RagotClone < RagotString

  include Ragot

  after :plap
  before :plap

  def plap
    'plop'
  end

end

class Stash < Array

  class << self

    attr_reader :stash

    def <<(stashed)
      (@stash ||= []) << stashed
    end

    attr_reader :before

  end

  include Ragot

end

class Couroucoucou

  include Ragot

  def self.after; end

end

Ragot.about RagotString, :to_sym

Ragot.about RagotString do
  ragot :name, class: true

  ragot :<<

  ragot :to_s, stamp: true
  ragot :to_c, env: :production
  ragot :to_i, env: [:production, :test]

  ragot :to_f do |result, *params|
    tell "`to_f` called, with params : '#{params.to_s}'. Got a whopping '#{result}' as result"
  end

  ragot :to_r, failsafe: true do
    bim!
  end

  ragot :to_str do
    bim!
  end
end

describe RagotClone do
  describe 'about' do
    let(:string) { described_class.new 'plop' }

    describe 'plop' do
      before {
        string.plap
      }

      it "should have logged the call to plop method" do
        expect(string.log).to eq [
          ["Entered plap, with params '[]', at #{string.log.first.first.scan(/at (.+)$/).first.first}"],
          ["`plap` called, with params : '[]'. Got 'plop' as result, at #{string.log.last.first.scan(/at (.+)$/).first.first}"],
        ]
      end
    end
  end
end

describe RagotString do
  describe 'about' do
    let(:string) { described_class.new 'plop' }

    describe 'to_sym' do
      before {
        string.to_sym
      }

      it "should have logged the call to to_sym method" do
        expect(string.log).to eq [ ["`to_sym` called, with params : '[]'. Got 'plop' as result, at #{string.log.first.first.scan(/at (.+)$/).first.first}"] ]
      end
    end

    describe 'to_s' do
      before {
        string.to_s
      }

      it "should have logged the access and the call to to_s method" do
        expect(string.log).to eq [
          ["Entered to_s, with params '[]', at #{string.log.first.first.scan(/at (.+)$/).first.first}"],
          ["`to_s` called, with params : '[]'. Got 'plop' as result, at #{string.log.last.first.scan(/at (.+)$/).first.first}"]
        ]
      end
    end

    describe 'to_f' do
      before {
        string.to_f
      }

      it "should have logged a message different from the default one" do
        expect(string.log).to eq [
          ["`to_f` called, with params : '[]'. Got a whopping '0.0' as result"]
        ]
      end
    end

    describe 'to_str' do
      it "shouldn't have logged anything and crash because of the buggy callback" do
        expect {string.to_str}.to raise_error(NoMethodError)
        expect(string.log).to be_nil
      end
    end

    describe 'to_r' do
      before {
        string.to_r
      }

      it "shouldn't have logged anything but not crash as well" do
        expect(string.log).to be_nil
      end
    end

    describe 'to_c' do
      before {
        string.to_c
      }

      it "shouldn't have logged anything" do
        expect(string.log).to be_nil
      end
    end

    describe 'to_i' do
      before {
        string.to_i
      }

      it "should have logged the access and the call to to_i method in production env" do
        expect(string.log).to eq [["`to_i` called, with params : '[]'. Got '0' as result, at #{string.log.first.first.scan(/at (.+)$/).first.first}"]]
      end
    end

    describe '<<' do
      before {
        string << 'inou'
      }

      it "should have logged the access to << method" do
        expect(string.log).to eq [["`<<` called, with params : '[\"inou\"]'. Got 'plopinou' as result, at #{string.log.first.first.scan(/at (.+)$/).first.first}"]]
      end
    end

    describe 'name' do
      before {
        RagotString.name
      }

      it "should have logged the access to name class method" do
        expect(RagotString.log).to eq [["`name` called, with params : '[]'. Got 'RagotString' as result, at #{RagotString.log.first.first.scan(/at (.+)$/).first.first}"]]
      end
    end
  end
end

Ragot.about JSON, :dump, class: true, stamp: true do |result, *_|
  Stash << "JSON produced #{result} with #{_}"
end

describe JSON do
  describe 'dump' do
    before {
      JSON.dump({ plop: true })
    }

    it "should stash what dump does" do
      expect(Stash.stash).to eq [ "JSON produced {\"plop\":true} with [{:plop=>true}]" ]
    end
  end
end

describe Stash do
  describe "before" do
    it "should not have made after class method available" do
      expect(described_class.respond_to?(:before, true)).to be_truthy
      expect(described_class.respond_to?(:ragot_before, true)).to be_truthy
      expect(described_class.respond_to?(:ragot_after, true)).to be_truthy
      expect(described_class.respond_to?(:after, true)).to be_falsy
    end
  end
end

describe Couroucoucou do
  describe "before" do
    it "should not have made before class method available" do
      expect(described_class.respond_to?(:after, true)).to be_truthy
      expect(described_class.respond_to?(:ragot_before, true)).to be_truthy
      expect(described_class.respond_to?(:ragot_after, true)).to be_truthy
      expect(described_class.respond_to?(:before, true)).to be_falsy
    end
  end
end
