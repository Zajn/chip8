# frozen_string_literal: true

require 'sdl2'
require 'debug'
require_relative './display'

class StackEmptyException < StandardError; end

class Chip8
  # Chip-8 programs conventionally start at 0x200; First 512 bytes
  # are reserved for the interpreter.
  START_ADDR = 0x200

  attr_reader :stack, :sound_timer, :delay_timer, :v
  attr_accessor :pc, :memory, :i, :display

  SDL2.init(SDL2::INIT_EVERYTHING)

  def initialize(rom_path: nil)
    @stack = []
    @memory = Array.new(4096, 0)
    @pc = 0
    @v = Array.new(0xf)
    @display = Display.new

    load_rom(rom_path) unless rom_path.nil?
    @pc = START_ADDR
    @sp = stack.length
  end

  def load_rom(path)
    f = File.open(File.expand_path(path, File.dirname(__FILE__)))

    pc = START_ADDR

    until f.eof?
      memory[pc] = f.readbyte
      pc += 1
    end
  end

  def fetch
    instruction = memory[@pc..@pc+1]
    @pc += 2

    instruction
  end

  def run
    running = true
    @pc = START_ADDR

    Kernel.trap('INT') { running = false }

    loop do
      while (ev = SDL2::Event.poll)
        exit if ev.is_a?(SDL2::Event::KeyDown) && ev.scancode == SDL2::Key::Scan::ESCAPE
        exit if ev.is_a?(SDL2::Event::Window) && ev.event == SDL2::Event::Window::CLOSE
      end
      instruction = fetch
      decode(instruction)
      render
    end
  end

  def step
    print @pc
    instruction = fetch
    decode(instruction)
  end

  #          ________________________
  #  ______ |_____ nnn  _____   _____|
  # | ins | |  x  |    |  y  | |  n  |
  # b b b b b b b b |  b b b b b b b b
  #
  def decode(instruction)
    op = high_nibble(instruction[0])
    x = low_nibble(instruction[0])
    y = high_nibble(instruction[1])
    n = low_nibble(instruction[1])
    nn = instruction[1]
    nnn = address(x, y, n)

    case op
    when 0x0
      case nn
      when 0xE0
        clear_screen
      when 0xEE
        ret
      end
    when 0x1
      jump(nnn)
    when 0x2
      subroutine(nnn)
    when 0x3
      skip_equal(get_register(x), nn)
    when 0x4
      skip_not_equal(get_register(x), nn)
    when 0x5
      skip_equal(get_register(x), get_register(y))
    when 0x6
      set_register(x, nn)
    when 0x7
      set_register(
        x,
        (get_register(x) + nn) % 256
      )
    when 0x8
      case n
      when 0x0
        set_register(x, get_register(y))
      when 0x1
        set_register(
          x,
          get_register(x) | get_register(y)
        )
      when 0x2
        set_register(
          x,
          get_register(x) & get_register(y)
        )
      when 0x3
        set_register(
          x,
          get_register(x) ^ get_register(y)
        )
      when 0x4
        temp = get_register(x) + get_register(y)
        set_register(
          x,
          temp % 256
        )
        if temp > 255
          set_register(0xF, 1)
        else
          set_register(0xF, 0)
        end

      # when 0x5
      # when 0x6
      # when 0x7
      # when 0xE
      end
    when 0xA
      seti(nnn)
    when 0xD
      draw(x, y, n)
    end
  end

  # TODO: Registers are 8-bit, so figure out what should happen if value is > 255
  def set_register(register, value)
    @v[register] = value
  end

  def jump(nnn)
    @pc = nnn
  end

  def get_register(register)
    @v[register]
  end

  def draw(vx, vy, n)
    x = get_register(vx) % Display::WIDTH
    y = get_register(vy) % Display::HEIGHT
    set_register(0xf, 0)

    n.times do |row|
      # 1. Get `row` byte, offset from I
      # 2. loop through pixels
      # # 1. If current pixel is on (1), and pixel at X,Y is on, turn off pixel and  VF=1
      # #    If current pixel is on (1), and pixel at X,Y is off, turn on pixel
      # # 2. If right-edge of screen is reached, stop drawing this row
      # # 3. increment x
      # 3. Increment Y
      x = get_register(vx) % Display::WIDTH
      pixels = memory[i + row]
      8.times.reverse_each do |bit|
        # TODO: Clip sprites that go past edge of screen

        if pixels[bit] == 1 && display.pixels[x][y] == 1
          display.pixels[x][y] = 0
          set_register(0xf, 1)
        elsif pixels[bit] == 1 && display.pixels[x][y].zero?
          display.pixels[x][y] = 1
        end

        x += 1
      end
      y += 1
    end
  end

  def ret
    raise StackEmptyException if stack.empty?

    @pc = @stack.pop
    @sp -= 1
  end

  def subroutine(addr)
    @sp += 1
    @stack.push(@pc)
    @pc = addr
  end

  def skip_equal(val1, val2)
    @pc += 2 if val1 == val2
  end

  def skip_not_equal(val1, val2)
    @pc += 2 if val1 != val2
  end

  def clear_screen
    display.clear
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

  def render
    display.render
  end
end
