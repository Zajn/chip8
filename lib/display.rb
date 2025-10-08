# frozen_string_literal: true

require 'sdl2'

class Display
  HEIGHT = 32
  WIDTH = 64
  SCALE = 30
  SCREEN_HEIGHT = HEIGHT * SCALE
  SCREEN_WIDTH = WIDTH * SCALE
  WHITE = [255, 255, 255, 255].freeze
  BLACK = [0, 0, 0, 255].freeze

  attr_reader :window, :renderer
  attr_accessor :pixels

  def initialize
    # TODO: I have this backwards, forcing me to transpose the array
    # I should rewrite this code to not use a nested array and create a helper
    # function to get a pixel given (x, y)
    @pixels = Array.new(WIDTH) { Array.new(HEIGHT, 0) }
    @window = create_window
    @renderer = window.create_renderer(-1, 0)
    blacken_screen
  end

  def render
    surface = frame_to_surface
    texture = renderer.create_texture_from(surface)
    renderer.draw_color = WHITE
    src_rect = SDL2::Rect.new(0, 0, WIDTH, HEIGHT)
    renderer.copy(texture, src_rect, nil)
    renderer.present
    surface.destroy
    texture.destroy
  end

  def clear
    @pixels = Array.new(WIDTH) { Array.new(HEIGHT, 0) }
  end

  private

  def create_window
    @window ||= SDL2::Window.create(
      'Chirb8',
      SDL2::Window::POS_CENTERED,
      SDL2::Window::POS_CENTERED,
      WIDTH * SCALE,
      HEIGHT * SCALE,
      SDL2::Window::Flags::ALLOW_HIGHDPI
    )
  end

  def blacken_screen
    renderer.draw_color = BLACK
    renderer.clear
  end

  def frame_to_surface
    bytes = pixels.transpose.flat_map do |row|
      row.flat_map do |bit|
        if bit == 1
          WHITE
        else
          BLACK
        end
      end
    end.pack('C*')

    SDL2::Surface.from_string(bytes, WIDTH, HEIGHT, 32)
  end
end
