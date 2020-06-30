# frozen_string_literal: true

class Disassemble
  attr_reader :rom
  attr_accessor :address, :buffer

  CHIP8_START_ADDR = 0x200

  def initialize(path_to_rom:)
    @rom = File.open(path_to_rom)
    initialize_buffer(file_size: rom.size)
  end

  def run
    read
    print(pc: CHIP8_START_ADDR)
  end

  def self.run(path_to_rom:)
    new(path_to_rom: path_to_rom).run
  end

  private

  def initialize_buffer(file_size:)
    # Chip-8 convention reserves first 512 bytes for interpreter
    # Programs start at 0x200
    @buffer = Array.new(file_size + 0x200)
  end

  def read
    pc = CHIP8_START_ADDR
    until rom.eof?
      @buffer[pc] = rom.readbyte
      pc += 1
    end
  end

  def print(pc: 0)
    @buffer = buffer[pc..-1] if pc != 0

    buffer.each_slice(2) do |a, b|
      printf('%<pc>04x %<a>02x %<b>02x ', { pc: pc, a: a, b: b })
      decode([a, b])
      pc += 2
    end
  end

  def decode(opcode)
    low_nibble = (opcode[0] >> 4)
    high_nibble = (opcode[0] & 0x0F)

    case low_nibble
    when 0x00
      puts format('0 not implemented yet')
    when 0x01
      puts format('1 not implemented yet')
    when 0x02
      puts format('2 not implemented yet')
    when 0x03
      puts format('3 not implemented yet')
    when 0x04
      puts format('4 not implemented yet')
    when 0x05
      puts format('5 not implemented yet')
    when 0x06
      puts format('%<op>-10s V%<variable>01x, #$%<arg>02x', { op: 'MVI', variable: high_nibble, arg: opcode[1] })
    when 0x07
      puts format('7 not implemented yet')
    when 0x08
      puts format('8 not implemented yet')
    when 0x09
      puts format('9 not implemented yet')
    when 0x0A
      puts format('%<op>-10s I, #$%<hi_addr>x%<arg>x', { op: 'MVI', hi_addr: high_nibble, arg: opcode[1] })
    when 0x0B
      puts format('B not implemented yet')
    when 0x0C
      puts format('C not implemented yet')
    when 0x0D
      puts format('D not implemented yet')
    when 0x0E
      puts format('E not implemented yet')
    when 0x0F
      puts format('F not implemented yet')
    end
  end
end

file_path, *_ignored = ARGV
Disassemble.run(path_to_rom: file_path)
