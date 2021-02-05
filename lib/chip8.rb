# frozen_string_literal: true

class Chip8
  # Chip-8 programs conventionally start at 0x200; First 512 bytes
  # are reserved for the interpreter.
  START_ADDR = 0x200

  attr_reader :stack, :sound_timer, :delay_timer,
              :V0, :V1, :V2, :V3, :V4, :V5, :V6, :V7, :V8, :V9,
              :VA, :VB, :VC, :VD, :VE, :VF
  attr_accessor :pc, :memory, :i

  def initialize
    @stack = []
    @memory = Array.new(4096)
    @pc = 0
  end

  def fetch
    instruction = memory[pc..pc+1]
    self.pc += 2

    instruction
  end

  def decode(instruction)
    op = high_nibble(instruction[0])
    x = low_nibble(instruction[0])
    y = high_nibble(instruction[1])
    n = low_nibble(instruction[1])
    nn = instruction[1]
    nnn = address(x, y, n)

    case op
    when 0x0
      case y
      when 0xE
        'clear screen'
      end
    when 0x1
      self.pc = nnn
    when 0x6
      set_register(x, nn)
    when 0x7
      add(x, nn)
    when 0xA
      seti(nnn)
    end
  end

  # TODO: Registers are 8-bit, so figure out what should happen if value is > 255
  # TODO: Seriously, just use an instance variable called V and make it an array of len 15
  def set_register(register, value)
    instance_variable_set("@V#{register}".to_sym, value)
  end

  def get_register(register)
    instance_variable_get("@V#{register}")
  end

  def draw(vx, vy, n)
    x = get_register(vx) % 64
    y = get_register(vy) % 32
    set_register()
  end

  private

  def low_nibble(byte)
    byte & 0x0f
  end

  def high_nibble(byte)
    byte >> 4
  end

  def address(*nibbles)
    nibbles[0] << 8 | nibbles[1] << 4 | nibbles[2]
  end

  def add(register, value)
    new_value = get_register(register) + value
    set_register(register, new_value)
  end

  def seti(value)
    self.i = value
  end
end
