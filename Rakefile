# frozen_string_literal: true

require_relative 'lib/chip8'
require_relative './disassemble'

task :run do |t|
  c = Chip8.new
  c.run
end

task :dump_rom do |t|
  _task_name, file_path, *_ignored = ARGV
  Disassemble.run(path_to_rom: file_path)
end
