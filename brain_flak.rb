require './stack.rb'

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

ARGV[1..-1].each do|a|
  active.push(a.to_i)
end

begin
  while true do
    current_symbol = source[source_index..source_index+1] or source[source_index]
    if source_index >= source.length then
      break
    end

    if ['()', '[]', '{}', '<>'].include? current_symbol
      case current_symbol
        when '()' then
          current_value += 1
        when '[]' then current_value -= 1
        when '{}' then current_value += active.pop
        when '<>' then active = active == left ? right : left
        else
          raise "Expected nilad found %s. This should never occur!" % current_symbol
      end
      source_index += 2

    else
      current_symbol = current_symbol[0]
      if is_opening_bracket?(current_symbol) then
        #If the stack is empty the enclosed code is skipped
        if current_symbol == '{' and active.peek == 0 then
          new_index = read_until_matching(source, source_index)
          if new_index == nil then
            raise BrainFlakError.new(
              "Unmatched open bracket. { opened at %d without matching closing bracket." % [source_index+1],
              source_index+1
            )
          else
            #Skip to end
            source_index = new_index
          end
        else
          main_stack.push([current_symbol, current_value, source_index])
        end
        current_value = 0

      elsif is_closing_bracket?(current_symbol) then
        data = main_stack.pop
        if data == nil then
          raise BrainFlakError.new(
            "Unmatched closing bracket. %s closed at %d without matching opening bracket."%[current_symbol, source_index + 1],
            source_index + 1
          )
        elsif not brackets_match?(data[0], current_symbol) then
          raise BrainFlakError.new(
            "Mismatched brackets. %s opened at %d closed by %s at %d."%[data[0], data[2] + 1, current_symbol, source_index + 1],
            source_index + 1
          )
        end

        case current_symbol
          when ')' then active.push(current_value)
          when ']' then puts current_value
          when '>' then current_value = 0
          when '}' then source_index = data[2] - 1 if active.peek != 0
          end

        current_value += data[1]
      elsif current_symbol.match(/\S/)
        raise BrainFlakError.new(
          "Illegal character: '%s' at %d."%[current_symbol, source_index + 1],
          source_index + 1
        )
      end
      source_index += 1
    end

    if source_index >= source_length then
      for item in main_stack do
        raise BrainFlakError.new(
          "Unmatched open bracket. %s opened at %d without matching closing bracket." % [item[0], item[2]],
          source_length
        )
      end
      break
    end

  end

  active.print
rescue BrainFlakError => e
  puts e.message
end
