require './stack.rb'
require './Interpreter.rb'

class BrainFlakError < StandardError

  attr_reader :cause, :pos

  def initialize(cause, pos)
    @cause = cause
    @pos = pos
    super("Error at character %d: %s" % [pos, cause])
  end
end

def read_until_matching(s, start)
  stack_height = 0
  s[start + 1..s.length].each_char.with_index(1) do |c, i|
    case c
    when '{' then stack_height += 1
    when '}' then
      stack_height -= 1
      if stack_height == -1 then
        return i + start
      end
    end
  end
  return nil
end

left = Stack.new('Left')
right = Stack.new('Right')
main_stack = []
active = left

source_index = 0
current_value = 0

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
