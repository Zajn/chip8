# frozen_string_literal: true

require 'sdl2'
require 'debug'
require 'logger'

class Chip8
  # Chip-8 programs conventionally start at 0x200; First 512 bytes
  # are reserved for the interpreter.
  START_ADDR = 0x200
  ROWS = 32
  COLS = 64
  SCALE = 30

  attr_reader :stack, :sound_timer, :delay_timer,
              :V0, :V1, :V2, :V3, :V4, :V5, :V6, :V7, :V8, :V9,
              :VA, :VB, :VC, :VD, :VE, :VF,
              :logger
  attr_accessor :pc, :memory, :i, :display

  SDL2.init(SDL2::INIT_EVERYTHING)

  def initialize
    @logger = Logger.new($stdout, progname: 'chirb8')
    @logger.warn!
    @stack = []
    @memory = Array.new(4096, 0)
    @pc = 0
    @display = Array.new(COLS) { Array.new(ROWS, 0) }
    @v = Array.new(0xf)

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

    window = SDL2::Window.create(
      'Chirb8',
      SDL2::Window::POS_CENTERED,
      SDL2::Window::POS_CENTERED,
      COLS * SCALE,
      ROWS * SCALE,
      SDL2::Window::Flags::ALLOW_HIGHDPI
    )

    @renderer = window.create_renderer(-1, 0)
    @renderer.draw_color = [0, 0, 0]
    @renderer.clear

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

  def create_renderer(window)
    window.create_renderer(-1, 0)
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
    logger.debug("OP: #{op}, x: #{x}, y: #{y}, n: #{n}, nn: #{nn}, nnn: #{nnn}")

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
    x = get_register(vx) % COLS
    y = get_register(vy) % ROWS
    set_register(0xf, 0)

    n.times do |row|
      # 1. Get `row` byte, offset from I
      # 2. loop through pixels
      # # 1. If current pixel is on (1), and pixel at X,Y is on, turn off pixel and  VF=1
      # #    If current pixel is on (1), and pixel at X,Y is off, turn on pixel
      # # 2. If right-edge of screen is reached, stop drawing this row
      # # 3. increment x
      # 3. Increment Y
      x = get_register(vx) % COLS
      pixels = memory[i + row]
      8.times.reverse_each do |bit|
        # TODO: Clip sprites that go past edge of screen

        if pixels[bit] == 1 && display[x][y] == 1
          display[x][y] = 0
          set_register(0xf, 1)
        elsif pixels[bit] == 1 && display[x][y].zero?
          display[x][y] = 1
        end

        x += 1
      end
      y += 1
    end
  end

  def render
    screen = display.transpose.flatten
    0.upto(ROWS * COLS - 1) do |i|
      x = i % COLS
      y = i.fdiv(COLS).floor

      draw_pixel(x, y) if screen[i].positive?
    end

    @renderer.present
  end

  def draw_pixel(x, y)
    @renderer.draw_color = [255, 255, 255]
    @renderer.fill_rect(
      SDL2::Rect.new(x * SCALE, y * SCALE, SCALE, SCALE)
    )
  end

  def clear_screen
    @display = Array.new(COLS) { Array.new(ROWS, 0) }
  end

  def screen_to_file
    f = File.new('display.txt', 'w')

    32.times do |y|
      64.times do |x|
        if display[x][y] == 1
          f.print "\u25A9"
        else
          f.print ' '
        end
      end

      f.print "\n"
    end

    f.close
  end

  def print_screen
    32.times do |y|
      64.times do |x|
        if display[x][y] == 1
          print "\u25A9"
        else
          print " "
        end
      end

      print "\n"
    end
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
