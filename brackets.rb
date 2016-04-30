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

  def push(n)
    @data.push(n)
  end
  
  def peek
    return @data.last
  end

  def print
    while @data.length > 1 do
        puts pop
    end
  end

  def talk
    puts @name
  end
end

def is_opening_bracket(b)
  return "([{<".include? b
end

def is_closing_bracket(b)
  return ")]}>".include? b
end

def brackets_match(b1, b2)
  s = [b1, b2].join("")
  return ["()", "[]", "{}", "<>"].include? s
end

def read_until_stack_end(s, start)
  stack_height = 0
  for i in (start + 1 .. s.length)
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

left = Stack.new("Left")
right = Stack.new("Right")
main_stack = Stack.new("Main")
active = left

source_file = File.open("source.brack", "r")
source = source_file.read
len = source.length

i = 0
n = 0
error = false
while true do
  cur = source[i..i+1] or source[i]
  if i >= source.length then
    break
  end

  if ['()', '[]', '{}', '<>'].include? cur then
    if cur == '()' then
      n += 1
    elsif cur == '[]' then
      n -= 1
    elsif cur == '{}' then
      n += active.pop
    else
      if active == left then 
        active = right
      else
        active = left
      end
    end
    i += 2
  else
    cur = cur[0]
    if is_opening_bracket(cur) then
      if cur == '{' and active.peek == 0 then
        new_index = read_until_stack_end(source, i)
        if new_index == nil then
          error = true
          break
        else
          i = new_index
        end
      else
        main_stack.push([cur, n, i])
      end
      n = 0
    elsif is_closing_bracket(cur) then
      data = main_stack.pop
      if not brackets_match(data[0], cur) then
        error = true
        break
      elsif cur == ')' then
        active.push(n)
      elsif cur == ']' then
        puts n
      elsif cur == '>' then
        n = 0
      elsif cur == '}' then
        if active.peek != 0 then
          i = data[2] - 1
        end
      end
    end
    i += 1
  end

  if i >= len then
    break
  end

end

if error then
  puts "Invalid character in source file!"
  exit
end

active.print
