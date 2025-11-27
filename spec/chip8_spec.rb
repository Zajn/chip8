# frozen_string_literal: true

require 'Chip8'

RSpec.describe Chip8 do
  it { is_expected.to respond_to :stack }
  it { is_expected.to respond_to :i }
  it { is_expected.to respond_to :sound_timer }
  it { is_expected.to respond_to :delay_timer }
  it { is_expected.to respond_to :pc }
  it { is_expected.to respond_to :v }

  describe '#initialize' do
    subject(:cpu) { Chip8.new }
    it 'initializes 4KB of memory' do
      expect(cpu.memory.size).to eq(4096)
    end

    it 'sets the program counter to the Chip8 start address' do
      expect(cpu.pc).to eq 0x200
    end
  end

  describe '#fetch' do
    subject(:cpu) { described_class.new }

    before do
      subject.memory[0x200] = 0xBE
      subject.memory[0x201] = 0xEF
    end

    it 'increments the program counter by 2' do
      prev_pc = cpu.pc
      cpu.fetch
      expect(cpu.pc).to eq(prev_pc + 2)
    end

    it 'returns a 2 byte instruction' do
      instruction = subject.fetch
      expect(instruction).to eq [0xBE, 0xEF]
    end
  end

  describe '#decode' do
    subject(:cpu) { described_class.new }

    context '0 opcodes' do
      let(:instruction) { [0x00, 0xE0] } # clear screen instruction
      let(:fake_display) { instance_double('Display') }

      before do
        allow(fake_display).to receive(:clear)
        cpu.display = fake_display
      end

      it 'clears the display' do
        expect(fake_display).to receive(:clear)
        cpu.decode(instruction)
      end
    end

    context '1 opcodes' do
      let(:instruction) { [0x13, 0x58] } # JMP NNN

      it 'sets the pc to NNN' do
        cpu.decode(instruction)
        expect(cpu.pc).to eq 0x358
      end
    end

    context '6 opcodes' do
      let(:instruction) { [0x61, 0xFF] } # mov V1, 0xFF

      it 'moves a value into the specified register' do
        cpu.decode(instruction)
        expect(cpu.v[0x1]).to eq 0xFF
      end

      it 'can set every register' do
        0x60.upto(0x6F) do |reg|
          instruction[0] = reg
          cpu.decode(instruction)
          reg_number = reg & 0x0F
          expect(cpu.get_register(reg_number)).to eq 0xFF
        end
      end
    end

    context '7 opcodes' do
      let(:instruction) { [0x76, 0xFF] }

      before do
        cpu.set_register(6, 0x2B)
      end

      it 'adds the value to the register' do
        cpu.decode(instruction)
        expect(cpu.v[0x6]).to eq 0x2A
      end
    end

    context 'A opcodes' do
      let(:instruction) { [0xA0, 0x45] }

      it 'sets I to the given value' do
        cpu.decode(instruction)
        expect(cpu.i).to eq 0x045
      end
    end
  end
end
