require './stack.rb'
require './Interpreter.rb'

if ARGV.length < 1 then
  puts "Welcome to Brain-Flak!"\
       "\nUsage:"\
       "brain_flak source_file"\
       "brain_flak source_file args\n"
  exit
end

source_path = ARGV[0]
if ARGV[1] == '-f'
  input_file = File.open(ARGV[2], 'r')
  numbers = input_file.read.gsub(/\s+/m, ' ').strip.split(" ")
elsif
  numbers = ARGV[1..-1]
end

source_file = File.open(source_path, 'r')
source = source_file.read
source_length = source.length

interpreter = BrainFlakInterpreter.new(source, numbers)

begin
  while interpreter.running do
    interpreter.step
  end

  interpreter.active_stack.print
rescue BrainFlakError => e
  puts e.message
end
