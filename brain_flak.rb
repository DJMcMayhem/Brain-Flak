class Stack
  def initialize(name)
    @name = name
    @data = []
  end

  def pop
    if @data.length != 0 then
      return @data.pop
    else
      return 0
    end
  end

  def push(current_value)
    @data.push(current_value)
  end
  
  def peek
    return @data.last || 0
  end

  def print
    while @data.length > 0 do
        puts pop
    end
  end

  def talk
    puts @name
  end
end

class BrainFlakError < StandardError

  attr_reader :cause, :pos

  def initialize(cause,pos)
    @cause = cause
    @pos = pos
    super("Error at character %d: %s" % [pos, cause])
  end
end

def is_opening_bracket?(b)
  return '([{<'.include? b
end

def is_closing_bracket?(b)
  return ')]}>'.include? b
end

def brackets_match?(b1, b2)
  s = [b1, b2].join('')
  return ['()', '[]', '{}', '<>'].include? s
end

def read_until_stack_end(s, start)
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
          raise "Expected niliad found %s. This should never occur!" % current_symbol
      end
      source_index += 2

    else
      current_symbol = current_symbol[0]
      if is_opening_bracket?(current_symbol) then
        if current_symbol == '{' and active.peek == 0 then
          new_index = read_until_stack_end(source, source_index)
          if new_index == nil then
            raise BrainFlakError.new(
              "Unmatched open bracket. { opened at %d without matching closing bracket." % [source_index+1],
              source_index+1
            )
          else
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
            "Unmatched closing bracket. %s closed at %d without matching opening bracket."%[current_symbol,source_index + 1],
            source_index + 1
          )
        elsif not brackets_match?(data[0], current_symbol) then
          raise BrainFlakError.new(
            "Mismatched brackets. %s opened at %d closed by %d at %d"%[data[0],data[2],current_symbol,source_index + 1],
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
