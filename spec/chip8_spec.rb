# frozen_string_literal: true

require 'Chip8'

RSpec.describe Chip8 do
  it { is_expected.to respond_to :stack }
  it { is_expected.to respond_to :i }
  it { is_expected.to respond_to :sound_timer }
  it { is_expected.to respond_to :delay_timer }
  it { is_expected.to respond_to :pc }

  it 'has 16 general purpose registers' do
    0.upto(15) do |v|
      expect(described_class.new).to respond_to "V#{v.to_s(16).upcase}".to_sym
    end
  end

  describe '#initialize' do
    it 'initializes 4KB of memory' do
      memory = Chip8.new.memory
      expect(memory.size).to eq(4096)
    end
  end
end
