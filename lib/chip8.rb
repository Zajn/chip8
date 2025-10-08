# frozen_string_literal: true

require 'sdl2'
require 'debug'
require_relative './display'

class Chip8
  # Chip-8 programs conventionally start at 0x200; First 512 bytes
  # are reserved for the interpreter.
  START_ADDR = 0x200

  attr_reader :stack, :sound_timer, :delay_timer,
              :V0, :V1, :V2, :V3, :V4, :V5, :V6, :V7, :V8, :V9,
              :VA, :VB, :VC, :VD, :VE, :VF
  attr_accessor :pc, :memory, :i, :display

  SDL2.init(SDL2::INIT_EVERYTHING)

  def initialize
    @stack = []
    @memory = Array.new(4096, 0)
    @pc = 0
    @v = Array.new(0xf)
    @display = Display.new

    load_rom('../ibm-logo.ch8')
    @pc = START_ADDR
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
        clear_screen
      end
    when 0x1
      jump(nnn)
    when 0x6
      set_register(x, nn)
    when 0x7
      add(x, nn)
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
