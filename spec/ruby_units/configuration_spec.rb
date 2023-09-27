require 'spec_helper'

describe RubyUnits::Configuration do
  
  context 'separator' do
    context '.separator is true' do
      it 'has a space between the scalar and the unit' do
        expect(RubyUnits::Unit.new('1 m').to_s).to eq '1 m'
      end
    end
  
    context '.separator is false' do
      around(:each) do |example|
        RubyUnits.configure do |config|
          config.separator = false
        end
        example.run
        RubyUnits.reset
      end
  
      it 'does not have a space between the scalar and the unit' do
        expect(RubyUnits::Unit.new('1 m').to_s).to eq '1m'
        expect(RubyUnits::Unit.new('14.5 lbs').to_s(:lbs)).to eq '14lbs, 8oz'
        expect(RubyUnits::Unit.new('220 lbs').to_s(:stone)).to eq '15stone, 10lb'
        expect(RubyUnits::Unit.new('14.2 ft').to_s(:ft)).to eq %(14'2")
        expect(RubyUnits::Unit.new('1/2 cup').to_s).to eq '1/2cu'
        expect(RubyUnits::Unit.new('123.55 lbs').to_s('%0.2f')).to eq '123.55lbs'
      end
    end
  end


  context 'preferred_conversion_fallback_method' do
    context 'default' do
      it 'is `:to_f` to convert to Float' do
        expect(RubyUnits.configuration.preferred_conversion_fallback_method).to eq(:to_f)
      end
      it 'makes Unit instances parse to Float when having decimals' do
        expect(RubyUnits::Unit.new('1.1 m').scalar).to eq(1.1)
        expect(RubyUnits::Unit.new('1.1 m').scalar).to be_a Float
      end
    end
  
    context 'when set to `:to_d` converts to BigDecimal' do
      around(:each) do |example|
        RubyUnits.configure do |config|
          config.preferred_conversion_fallback_method = :to_d
        end
        example.run
        RubyUnits.reset
      end
  
      it 'makes Unit instances parse to Float when having decimals' do
        expect(RubyUnits::Unit.new('1.1 m').scalar).to eq(1.1)
        expect(RubyUnits::Unit.new('1.1 m').scalar).to be_a BigDecimal
      end
    end
  end
  
end
