require './stack.rb'
require './Interpreter.rb'

require 'optparse'

debug = false
arg_path = ""

parser = OptionParser.new do |opts|
  # This needs updating
  opts.banner = "Welcome to Brain-Flak!"\
                "\nUsage:"\
                "brain_flak source_file"\
                "brain_flak source_file args\n"

  opts.on("-d", "--debug", "Enables parsing of debug commands") do
    debug = true
  end

  opts.on("-f", "--argument-file=FILE", "Reads arguments for the brain-flak program from FILE and ignores those provided as command line arguments") do |file|
    arg_path = file
  end
end

begin
  parser.order!
rescue OptionParser::ParseError => e
  puts e
  puts "\n"
  puts parser
  exit
end
# parser.order! removes all the option flags from ARGV
# so all is left is the brain-flak file and the arguments
if ARGV.length < 1 then
  puts parser
  exit
end

source_path = ARGV[0]
if arg_path != "" then
  input_file = File.open(arg_path, 'r')
  numbers = input_file.read.gsub(/\s+/m, ' ').strip.split(" ")
else
  numbers = ARGV[1..-1]
end

if debug then
  puts "Debug mode... ENGAGED!"
end

source_file = File.open(source_path, 'r')
source = source_file.read
source_length = source.length

begin
  numbers.each do |a|
    raise BrainFlakError.new("Invalid integer in input: \"%s\""%[a], 0) if !(a =~ /^-?\d+$/)
  end
  numbers.map! { |n| n.to_i }
  interpreter = BrainFlakInterpreter.new(source, numbers, [], debug)

  while interpreter.running do
    interpreter.step
  end

  interpreter.finish
  interpreter.active_stack.print
rescue BrainFlakError => e
  STDERR.puts e.message
end
