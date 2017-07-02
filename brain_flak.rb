require_relative './stack.rb'
require_relative './BrainFlakInterpreter.rb'
require_relative './BrainFlueueInterpreter.rb'
require_relative './ClassicInterpreter.rb'
require_relative './BraceCheck.rb'

VERSION_STRING =  "Brain-Flak Ruby Interpreter v1.5.1-dev"

require 'optparse'

debug = false
quiet = false
do_in = true
do_out = true
ascii_in = false
ascii_out = false
reverse = false
arg_path = ""
max_cycles = -1
mode = "brainflak"
from_file = true

parser = OptionParser.new do |opts|
  opts.banner = "\nBrain-Flak Ruby Interpreter\n"\
                "Usage:\n"\
                "\tbrain_flak [options] source_file args...\n\n"

  opts.on("-d", "--debug", "Enables parsing of debug commands.") do
    debug = true
  end
  opts.on("-qd","--quiet-debug", "Makes debug produce less output.") do
    quiet = true
    if !debug
      debug = true
    end
  end
  opts.on("-H", "--help-debug", "Prints a list of debug flags and what they do.") do
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

  opts.on("-l","--language=LANGUAGE", "Changes the language to be interpreted.  Brain-Flak is the default but Miniflak, Brain-Flueue and Brain-Flak-Classic are also options.") do |lang|
    mode = lang[0..-1].downcase.strip.gsub("-fl","fl")
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

  opts.on("-n","--no-in", "Input is ignored.") do
    do_in = false
  end

  opts.on("-N","--no-out", "No output is produced.  Debug flags and error messages still appear.") do
    do_out = false
  end

  opts.on("-r", "--reverse", "Reverses the order that arguments are pushed onto the stack AND that values are printed at the end.") do
    reverse = true
  end

  opts.on("-h", "--help", "Prints info on the command line usage of Brain-Flak and then exits.") do
    STDERR.puts opts
    exit
  end

  opts.on("-v", "--version", "Prints the version of the Brain-Flak interpreter and then exits.") do
    STDERR.puts VERSION_STRING
    exit
  end

  opts.on("-m", "--max-cycles=MAX", "Sets the maximum cycles.  If exceeded the program will terminate.") do |maximum|
    #Can cause errors
    max_cycles = maximum.to_i
  end

  opts.on("-e", "--execute", "Executes the first command line argument as Brain-Flak code.") do
    from_file = false
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

if debug and !quiet then
  STDERR.puts "Debug mode... ENGAGED!"
end

if from_file then
  source_file = File.open(source_path, 'r')
  source = source_file.read
  source_length = source.length
else
  source = source_path      # contains ARGV[0]
end

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

  #Check the braces are matched
  braceCheck(source)

  case mode
  when "brainflak"
    interpreter = BrainFlakInterpreter.new(source, numbers, [], debug, max_cycles)
  when "classic"
    interpreter = ClassicInterpreter.new(source, numbers, [], debug, max_cycles)
  when "miniflak"
    while source =~ /\[\]/
      source = source.gsub(/#.*\n/,"").gsub(/[^<>\[\]{}()]/,"").gsub("<","").gsub(">","").gsub("[]","")
    end
    interpreter = BrainFlakInterpreter.new(source, numbers, [], debug, max_cycles)
  when "brainflueue"
    interpreter = BrainFlueueInterpreter.new(source, numbers, [], debug, max_cycles)
  when "flueue"
    interpreter = BrainFlueueInterpreter.new(source, numbers, [], debug, max_cycles)
  else 
    raise BrainFlakError.new("No language called '%s'." % mode, 0)
  end
  while interpreter.step
  end
  if interpreter.main_stack.length > 0
    unmatched_brak = interpreter.main_stack[0]
    raise BrainFlakError.new("Unmatched '%s' character." % unmatched_brak[0], unmatched_brak[2] + 1)
  end
  if do_out then
    begin
      #Output current state
      if debug and !quiet then
        puts interpreter.debug_info_full(ascii_out)
      else
        interpreter.active_stack.print_stack(ascii_out, reverse)
      end
    rescue BrainFlakError => e
      if e.pos == -1 then
        #Catch an error from the stack, becuase the stack does not know where it is in the program
        #We remove the beginning of the message (everything before ": ") and make a new error 
        #with the location being the end of the program
        raise BrainFlakError.new(e.message.split(": ")[1..-1].join(": "), source_length)
      else
        raise e
      end
    end
  end

rescue BrainFlakError => e
  STDERR.puts e.message

rescue Interrupt
  STDERR.puts "\nKeyboard Interrupt"
  STDERR.puts interpreter.inspect
  if debug and !quiet then
    STDERR.puts interpreter.debug_info
  end

rescue RuntimeError => e
  if e.to_s == "Second Interrupt"
    STDERR.puts interpreter.inspect
    if debug and !quiet then
      STDERR.puts interpreter.debug_info
    end
  else
    raise e   
  end
end

