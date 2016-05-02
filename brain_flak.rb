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
    if @data.length != 0 then return @data.last
    else
      return 0  
    end  
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
  for i in (start + 1..s.length)
    if s[i] == '{' then
      stack_height += 1
    elsif s[i] == '}'
      stack_height -= 1
      if stack_height == -1 then
        return i
      end
    end
  end
  return nil
end

left = Stack.new('Left')
right = Stack.new('Right')
main_stack = Stack.new('Main')
active = left

source_index = 0
current_value = 0
error = false

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

while true do
  current_symbol = source[source_index..source_index+1] or source[source_index]
  if source_index >= source.length then
    break
  end

  if ['()', '[]', '{}', '<>'].include? current_symbol 
    case current_symbol
      when '()' then current_value += 1
      when '[]' then current_value -= 1
      when '{}' then current_value += active.pop
      when '<>' then active = active == left ? right : left
      else
        error = true
        break
    end
    source_index += 2

  else
    current_symbol = current_symbol[0]
    if is_opening_bracket?(current_symbol) then
      if current_symbol == '{' and active.peek == 0 then
        new_index = read_until_stack_end(source, source_index)
        if new_index == nil then
          error = true
          break
        else
          source_index = new_index
        end
      else
        main_stack.push([current_symbol, current_value, source_index])
      end
      current_value = 0
    elsif is_closing_bracket?(current_symbol) then
      data = main_stack.pop
      if not brackets_match?(data[0], current_symbol) then
        error = true
        break
      end

      case current_symbol
        when ')' then active.push(current_value)
        when ']' then puts current_value
        when '>' then current_value = 0
        when '}' then source_index = data[2] - 1 if active.peek != 0
        end
    end
    source_index += 1
  end

  if source_index >= source_length then
    break
  end

#  puts current_symbol
#  puts "Active:"
#  active.talk
#  puts "Left:"
#  left.print
#  puts "Right:"
#  right.print
#  STDIN.gets.chomp

end

if error then
  puts 'Invalid character in source file!'
  exit
end

active.print
