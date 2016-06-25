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

class BrainFlakInterpreter

  attr_reader :active_stack, :running

  def initialize(source, args)
    @source = source
    @left = Stack.new('Left')
    @right = Stack.new('Right')
    @main_stack = []
    @active_stack = @left
    @index = 0
    @current_value = 0
    @running = @source.length > 0
    args.each do|a|
      @active_stack.push(a.to_i)
    end
  end

  def step()
    if @running == false then
      return false
    end
    current_symbol = @source[@index..@index+1] or @source[@index]
    if ['()', '[]', '{}', '<>'].include? current_symbol
      case current_symbol
        when '()' then @current_value += 1
        when '[]' then @current_value -= 1
        when '{}' then @current_value += @active_stack.pop
        when '<>' then @active_stack = @active_stack == @left ? @right : @left
      end
      @index += 2
    else
      current_symbol = current_symbol[0]
      if is_opening_bracket?(current_symbol) then
        if current_symbol == '{' and @active_stack.peek == 0 then
          new_index = read_until_matching(@source, @index)
          raise BrainFlakError.new("Unmatched {", @index + 1) if new_index == nil
          @index = new_index
        else
          @main_stack.push([current_symbol, @current_value, @index])
        end
        @current_value = 0

      elsif is_closing_bracket?(current_symbol) then
        data = @main_stack.pop
        raise BrainFlakError.new("Unmatched " + current_symbol, source_index + 1) if data == nil
        raise BrainFlakError.new("Mismatched closing bracket %s. Expected to close %s at character %d" % [current_symbol, data[0], data[2] + 1], @index + 1) if not brackets_match?(data[0], current_symbol)

        case current_symbol
          when ')' then @active_stack.push(@current_value)
          when ']' then puts @current_value
          when '>' then @current_value = 0
          when '}' then @index = data[2] - 1 if @active_stack.peek != 0
        end
        @current_value += data[1]
      end
      @index += 1
    end
    if @index >= @source.length then
      @running = false
    end
  end
end
