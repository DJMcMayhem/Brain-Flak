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
source_file = File.open(source_path, 'r')
source = source_file.read
source_length = source.length

interpreter = BrainFlakInterpreter.new(source, ARGV[1..-1])

begin
  while interpreter.running do
    interpreter.step
  end

  interpreter.active_stack.print
rescue BrainFlakError => e
  puts e.message
end
