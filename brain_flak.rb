require_relative './stack.rb'
require_relative './Interpreter.rb'

require 'optparse'

classic = false
debug = false
ascii_in = false
ascii_out = false
reverse = false
utf8 = false
arg_path = ""

parser = OptionParser.new do |opts|
  opts.banner = "\nBrain-Flak Ruby Interpreter\n"\
                "Usage:\n"\
                "\tbrain_flak [options] source_file args...\n\n"

  opts.on("-C", "--classic", "Runs code as Brain-Flak Classic code") do
    classic = true
  end

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

  opts.on("-r", "--reverse", "Reverses the order that arguments are pushed onto the stack AND that values are printed at the end.") do
    reverse = true
  end

  opts.on("-u", "--utf8", "Enables handling of UTF-8 characters in input and output") do
    utf8 = true
  end

  opts.on("-h", "--help", "Prints info on the command line usage of Brain-Flak and then exits") do
    STDERR.puts opts
    exit
  end

  opts.on("-v", "--version", "Prints the version of the Brain-Flak interpreter and then exits") do
    STDERR.puts "Brain-Flak Ruby Interpreter v1.0.0"
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
if arg_path != "" then
  input_file = File.open(arg_path, 'r')
  if !ascii_in
    numbers = input_file.read.gsub(/\s+/m, ' ').strip.split(" ")
  else
    numbers = input_file.read.split("")
  end

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
    if !utf8 then
      numbers.each do |a|
        raise BrainFlakError.new("Invalid character in input: \"%s\"" % [a.chr(Encoding::UTF_8)], 0) if a > 255
      end
    end
  end
  numbers.reverse! if !reverse
  interpreter = BrainFlakInterpreter.new(source, numbers, [], debug, classic)

  while interpreter.step
  end
  if interpreter.main_stack.length > 0
    unmatched_brak = interpreter.main_stack[0]
    raise BrainFlakError.new("Unclosed %s character." % unmatched_brak[0].gsub(/:/,"["), unmatched_brak[2])
  end
  interpreter.active_stack.print_stack(ascii_out,reverse,utf8)
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

