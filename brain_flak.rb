require_relative './stack.rb'
require_relative './Interpreter.rb'

VERSION_STRING =  "Brain-Flak Ruby Interpreter v1.3.1-dev"

require 'optparse'

debug = false
do_in = true
do_out = true
ascii_in = false
ascii_out = false
reverse = false
arg_path = ""

parser = OptionParser.new do |opts|
  opts.banner = "\nBrain-Flak Ruby Interpreter\n"\
                "Usage:\n"\
                "\tbrain_flak [options] source_file args...\n\n"

  opts.on("-d", "--debug", "Enables parsing of debug commands") do
    debug = true
  end

  opts.on("-H", "--help-debug", "Prints a list of debug flags and what they do") do
    flag_desc= [
      ["ac","Prints the current stack as ASCII characters"],
      ["al","Prints the left stack as ASCII characters"],
      ["av","Prints the current value of the scope as an ASCII character"],
      ["ar","Prints the right stack as ASCII characters"],
      ["cy","Prints the number of elapsed cycles"],
      ["dc","Prints the current stack in decimal"],
      ["dh","Prints the height of the current stack in decimal"],
      ["dl","Prints the left stack in decimal"],
      ["dv","Prints the current value of the scope in decimal"],
      ["dr","Prints the right stack in decimal"],
      ["ex","Terminates the program"],
      ["ij","Pauses program and prompts user for Brain-Flak code to be run in place of the flag"],
      ["lt","Passed with a number after the @lt (e.g. @lt6).  Evaluates to the number passed with it"],
      ["pu","Pauses the program until the user hits the return key"],
    ]    
    flag_desc.each do | flag |
      STDERR.puts "   "+flag[0]+":       "+flag[1]
    end
  end

  opts.on("-f", "--file=FILE", "Reads input for the brain-flak program from FILE, rather than from the command line.") do |file|
    arg_path = file
  end

  opts.on("-a", "--ascii-in", "Take input in character code points and output in decimal. This overrides previous -A and -c flags.") do 
    ascii_in = true
    ascii_out = false
  end

  opts.on("-A", "--ascii-out", "Take input in decimal and output in character code points. This overrides previous -a and -c flags.") do 
    ascii_in = false
    ascii_out = true
  end

  opts.on("-c", "--ascii", "Take input and output in character code points, rather than in decimal. This overrides previous -a and -A flags.") do 
    ascii_in = true
    ascii_out = true
  end

  opts.on("-n","--no-in", "Input is ignored") do
    do_in = false
  end

  opts.on("-N","--no-out", "No output is produced.  Debug flags and error messages still appear") do
    do_out = false
  end

  opts.on("-r", "--reverse", "Reverses the order that arguments are pushed onto the stack AND that values are printed at the end.") do
    reverse = true
  end

  opts.on("-h", "--help", "Prints info on the command line usage of Brain-Flak and then exits") do
    STDERR.puts opts
    exit
  end

  opts.on("-v", "--version", "Prints the version of the Brain-Flak interpreter and then exits") do
    STDERR.puts VERSION_STRING
    exit
  end
end

begin
  parser.order!
rescue OptionParser::ParseError => e
  STDERR.puts e
  STDERR.puts "\n"
  STDERR.puts parser
  exit
end

if ARGV.length < 1 then
  STDERR.puts parser
  exit
end

source_path = ARGV[0]
#No input
if !do_in then
  numbers = []
#Input from file
elsif arg_path != "" then
  input_file = File.open(arg_path, 'r:UTF-8')
  if !ascii_in
    numbers = input_file.read.gsub(/\s+/m, ' ').strip.split(" ")
  else
    numbers = input_file.read.split("")
  end
#Input from command line
else
  if ascii_in
    numbers = ARGV[1..-1].join(" ").split("")
  else
    numbers = ARGV[1..-1]
  end
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
      raise BrainFlakError.new("Invalid integer in input: \"%s\"" % [a], 0) if !(a =~ /^-?\d+$/)
    end
    numbers.map!(&:to_i)
  else
    numbers.map!(&:ord)
  end
  numbers.reverse! if !reverse
  interpreter = BrainFlakInterpreter.new(source, numbers, [], debug)

  while interpreter.step
  end
  if interpreter.main_stack.length > 0
    unmatched_brak = interpreter.main_stack[0]
    raise BrainFlakError.new("Unmatched '%s' character." % unmatched_brak[0], unmatched_brak[2] + 1)
  end
  if do_out then
    interpreter.active_stack.print_stack(ascii_out, reverse)
  end

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

