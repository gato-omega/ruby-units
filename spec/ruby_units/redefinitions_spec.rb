require 'spec_helper'

describe 'RubyUnits::Unit#redefine!' do

  # We need to test these redefinitions since for some unexpected reason
  # when altering the <liter> unit (and possibly, any other) the conversions
  # start losing some precision on the floating point decimals.
  # But whenever the definitions are left alone this does not happen!
  # We guess is something to do with the cache, but even after inspecting it
  # the reason is still unclear.
  #
  # We can reproduce by adjusting:
  # - redefinition_enabled? -> perform redefinitions? to `true`
  # - redefinition_method   -> use any of :normal | :direct
  # - call_setup?           -> whether to call RubyUnits::Unit.setup after performing changes (used with :direct) (true|false)
  context 'redefining non-base units definitions' do

    def redefinition_enabled?
      true
    end

    def redefinition_method
      # return :normal # by using #redefine! as it is intended via the public API methods
      return :direct # by directly mutating the internal definitions Hash structure
    end

    def test_redefinition_method_block(method_to_use, &block)
      if redefinition_enabled?
        raise "No redefinition method: `#{method_to_use}`" unless %i(normal direct).include?(method_to_use)
        raise 'No redefinition logic block passed' unless block_given?
        yield if redefinition_method == method_to_use
      end
      # Must call setup to clear the cache on this (Even with this, we still get abnormal behavior!)
      RubyUnits::Unit.setup if call_setup?
    end

    # Whether to run the expectations related to the precision loss issues.
    def test_redefinition_issues?
      true
    end
    
    def call_setup?
      true
    end

    # Ugly inspect method left here for testing purposes since this
    # issue with redefinitions has not been resolved yet.
    def inspect_internal_liters_and_cache(name)
      puts ''
      puts ''
      puts ''
      puts "BEGIN ============== Inspecting #{name} =============="
      puts "RubyUnits::Unit.definitions['<liter>']"
      p RubyUnits::Unit.definitions['<liter>']
      puts "RubyUnits::Unit.unit_map"
      p RubyUnits::Unit.unit_map.select{|k,v| %w(L liter liters litre litres).include?(k) }
      puts "RubyUnits::Unit.unit_values['<liter>']"
      p RubyUnits::Unit.unit_values['<liter>']
      puts ''
      puts "===== CACHES BEGIN ====="
      puts "RubyUnits::Unit.cached"
      p RubyUnits::Unit.cached
      puts "RubyUnits::Unit.base_unit_cache"
      p RubyUnits::Unit.base_unit_cache
      puts "===== CACHES END ====="
      puts ''
      puts "===== REGEXES BEGIN ====="
      puts "RubyUnits::Unit.unit_match_regex"
      p RubyUnits::Unit.unit_match_regex
      puts "RubyUnits::Unit.temp_regex"
      p RubyUnits::Unit.temp_regex
      puts "RubyUnits::Unit.prefix_regex"
      p RubyUnits::Unit.prefix_regex
      puts "RubyUnits::Unit.unit_regex"
      p RubyUnits::Unit.unit_regex
      puts "===== REGEXES END ====="
      puts "END ============== Inspecting #{name} =============="
      puts ''
      puts ''
      puts ''
    end

    context 'redefining the existing <liter> unit to remove lowercase `l` and use `L` instead.' do
      before do
        
        test_redefinition_method_block(:normal) do
          RubyUnits::Unit.redefine!('liter') do |liter|
            liter.aliases      = %w[L liter liters litre litres]
            liter.display_name = 'L'
          end
        end

        test_redefinition_method_block(:direct) do
          RubyUnits::Unit.definitions['<liter>'].aliases      = %w[L liter liters litre litres]
          RubyUnits::Unit.definitions['<liter>'].display_name = 'L'
        end

      end

      context 'precision must not be lost' do
        it 'when working in the same units (L)' do
          # We need multiple cases here to make sure no conversion pathways lead to precision loss.
          expect(RubyUnits::Unit.new('1000 L')    - RubyUnits::Unit.new('800 L')).to    eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new('1000.0 L')  - RubyUnits::Unit.new('800 L')).to    eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new('1000 L')    - RubyUnits::Unit.new('800.0 L')).to  eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200.0, 'L'))
        end

        it 'when working with smaller compatible units (mL)' do
          # We need multiple cases here to make sure no conversion pathways lead to precision loss.
          expect(RubyUnits::Unit.new('1000 L')    - RubyUnits::Unit.new('800000 mL')).to    eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200.0, 'L'))

          # inspect_internal_liters_and_cache('BEFORE')

          # These still fail (probably better to convert to smallest unit (even if not a base unit?) such that divisions are avoided as much as possible)
          # Compare these examples to the ones without redefinition.
          # Also, you sometimes might get flaky specs in the ones without redefinition if you randomize example run order and do not call `RubyUnits::Unit.setup`.
          if test_redefinition_issues?

            # binding.pry

            begin
              expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new('200 L'))
              expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200, 'L'))
              expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200.0, 'L'))
              expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new('200 L'))
              expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200, 'L'))
              expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200.0, 'L'))
              expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new('200 L'))
              expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200, 'L'))
              expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200.0, 'L'))
            ensure
              # inspect_internal_liters_and_cache('AFTER')
            end
          end
        end
      end
      
      after do
        # Leave everything the way it was since the
        # other specs need this unchanged.
        test_redefinition_method_block(:normal) do
          RubyUnits::Unit.redefine!('liter') do |liter|
            liter.aliases      = %w[l L liter liters litre litres]
            liter.display_name = 'l'
          end
        end

        test_redefinition_method_block(:direct) do
          RubyUnits::Unit.definitions['<liter>'].aliases      = %w[l L liter liters litre litres]
          RubyUnits::Unit.definitions['<liter>'].display_name = 'l'
        end
      end

    end

    context 'NOT redefining any pre-existing definitions' do

      context 'precision must not be lost' do
        it 'when working in the same units (L)' do
          # We need multiple cases here to make sure no conversion pathways lead to precision loss.
          expect(RubyUnits::Unit.new('1000 L')    - RubyUnits::Unit.new('800 L')).to    eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new('1000.0 L')  - RubyUnits::Unit.new('800 L')).to    eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new('1000 L')    - RubyUnits::Unit.new('800.0 L')).to  eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800, 'L')).to   eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800.0, 'L')).to eq(RubyUnits::Unit.new(200.0, 'L'))
        end

        it 'when working with smaller compatible units (mL)' do
          # We need multiple cases here to make sure no conversion pathways lead to precision loss.
          expect(RubyUnits::Unit.new('1000 L')    - RubyUnits::Unit.new('800000 mL')).to    eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200.0, 'L'))

          # These DON'T fail whenever redefinitions are not made, which is incredibly unexpected.
          # Even if we do not alter the order of the internal cache or definitions Hash.
          # Also, you sometimes might get flaky specs here if you randomize example run order
          # calling `RubyUnits::Unit.setup` seems to make this work much better (even with :normal redefinition method)
          # but it shouldn't have any effect since that's already internally called, so...idk???
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000, 'mL')).to   eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000.0, 'L') - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200.0, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new('200 L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200, 'L'))
          expect(RubyUnits::Unit.new(1000, 'L')   - RubyUnits::Unit.new(800000.0, 'mL')).to eq(RubyUnits::Unit.new(200.0, 'L'))
        end
      end

    end

  end
end