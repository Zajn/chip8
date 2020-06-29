# frozen_string_literal: true
require 'pry'
require 'pry-byebug'

class Disassemble
  attr_reader :rom, :buffer
  attr_accessor :address

  CHIP8_START_ADDR = 0x200
  def initialize(path_to_rom:)
    @rom = File.open(path_to_rom)
    @buffer = initialize_buffer(file_size: rom.size)
  end

  def run
    pc = CHIP8_START_ADDR
    until rom.eof?
      byte = rom.readbyte
      puts "DEBUG: #{pc}"
      buffer[pc] = format('%<byte>x', { byte: byte })
      pc += 1
    end

    print(pc: CHIP8_START_ADDR)
  end

  def self.run(path_to_rom:)
    new(path_to_rom: path_to_rom).run
  end

  def initialize_buffer(file_size:)
    # Chip-8 convention reserves first 512 bytes for interpreter
    # Programs start at 0x200
    Array.new(file_size + 0x200)
  end

  def print(pc: 0)
    buffer.each_slice(2) do |a, b|
      puts format("%<pc>04x %<a>s %<b>s", { pc: pc, a: a, b: b })
      pc += 2
    end

    puts buffer.size
  end
end

file_path, *_ignored = ARGV
Disassemble.run(path_to_rom: file_path)
