require_relative './stack.rb'
require_relative './Interpreter.rb'

require 'optparse'

debug = false
ascii_in = false
ascii_out = false
arg_path = ""

parser = OptionParser.new do |opts|
  # This needs updating
  opts.banner = "Welcome to Brain-Flak!\n\n"\
                "Usage:\n"\
                "\tbrain_flak source_file\n"\
                "\tbrain_flak source_file args\n\n"

  opts.on("-d", "--debug", "Enables parsing of debug commands") do
    debug = true
  end

  opts.on("-f", "--file=FILE", "Reads input for the brain-flak program from FILE, rather than from the command line.") do |file|
    arg_path = file
  end

  opts.on("-a", "--ascii-in", "Take input in ASCII code points and output in decimal. This overrides previous -A and -c flags.") do 
    ascii_in = true
    ascii_out = false
  end

  opts.on("-A", "--ascii-out", "Take input in decimal and output in ASCII code points. This overrides previous -a and -c flags.") do 
    ascii_in = false
    ascii_out = true
  end

  opts.on("-c", "--ascii", "Take input and output in ASCII code points, rather than in decimal. This overrides previous -a and -A flags.") do 
    ascii_in = true
    ascii_out = true
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

if ARGV.length < 1 then
  puts parser
  exit
end

source_path = ARGV[0]
if arg_path != "" then
  input_file = File.open(arg_path, 'r')
  if !ascii_in
    numbers = input_file.read.gsub(/\s+/m, ' ').strip.split(" ")
  else
    numbers = input_file.read.split("").map(&:ord)
  end

else
  if ascii_in and ARGV.length > 1
    puts "ASCII mode (-a) and command line input are incompatible.\nTry giving input from a file.\n"
    exit
  end
  numbers = ARGV[1..-1].reverse
end

if debug then
  STDERR.puts "Debug mode... ENGAGED!"
end

source_file = File.open(source_path, 'r')
source = source_file.read
source_length = source.length

begin
  if !ascii_in
    numbers.each do |a|
      raise BrainFlakError.new("Invalid integer in input: \"%s\""%[a], 0) if !(a =~ /^-?\d+$/)
    end
    numbers.map! { |n| n.to_i }
  else
    numbers.map! { |c| c.ord }
  end
  interpreter = BrainFlakInterpreter.new(source, numbers, [], debug)

  while interpreter.step
  end
  if interpreter.main_stack.length > 0
    unmatched_brak = interpreter.main_stack[0]
    raise BrainFlakError.new("Unclosed '%s' character." % unmatched_brak[0], unmatched_brak[2])
  end
  interpreter.active_stack.print_stack(ascii_out)
rescue BrainFlakError => e
  STDERR.puts e.message
rescue Interrupt
  STDERR.puts "\nKeyboard Interrupt"
  STDERR.puts interpreter.inspect
  if debug then
    STDERR.puts interpreter.debug_info
  end
rescue RuntimeError => e
  if e.to_s == "Second Interrupt"
    STDERR.puts interpreter.inspect
    if debug then
      STDERR.puts interpreter.debug_info
    end
  else
    raise e   
  end
end

