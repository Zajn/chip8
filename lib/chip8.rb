# frozen_string_literal: true

class Chip8
  # Chip-8 programs conventionally start at 0x200; First 512 bytes
  # are reserved for the interpreter.
  START_ADDR = 0x200

  attr_reader :memory, :stack, :i, :pc, :sound_timer, :delay_timer,
              :V0, :V1, :V2, :V3, :V4, :V5, :V6, :V7, :V8, :V9,
              :VA, :VB, :VC, :VD, :VE, :VF

  def initialize
    @stack = []
    @memory = Array.new(4096)
  end
end
