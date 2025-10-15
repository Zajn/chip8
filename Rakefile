# frozen_string_literal: true

require 'pathname'
require_relative 'lib/chip8'
require_relative './disassemble'

task :run do |_t|
  _task_name, file_path, *_ignored = ARGV

  rom_path = Pathname.new(file_path).expand_path

  c = Chip8.new(rom_path:)
  c.run
end

task :dump_rom do |_t|
  _task_name, file_path, *_ignored = ARGV
  Disassemble.run(path_to_rom: file_path)
end

task :test_opcodes do |_t|
  Chip8.new(
    rom_path: Pathname.new('./test_opcode.ch8').expand_path
  ).run
end
