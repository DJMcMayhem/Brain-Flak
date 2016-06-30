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

  def initialize(source, args, debug)
    # Strips the source of any characters that aren't brackets or part of debug flags
    @source = source.gsub(/(?:(?<=[()\[\]{}<>])|\s|^)[^#()\[\]{}<>]+/, "")
    @left = Stack.new('Left')
    @right = Stack.new('Right')
    @main_stack = []
    @active_stack = @left
    @index = 0
    @current_value = 0
    @running = @source.length > 0
    # Hash.new([]) does not work since modifications change that original array
    @debug_flags = Hash.new{|h,k| h[k] = []} if debug
    @last_op = :none
    args.each do|a|
      if a =~ /\d+/
        @active_stack.push(a.to_i)
      else
        raise BrainFlakError.new("Invalid integer in input", 0)
      end
    end
    remove_debug_flags(debug)
  end

  def remove_debug_flags(debug)
    while match = /#[^#()\[\]{}<>]*/.match(@source) do
      str = @source.slice!(match.begin(0)..match.end(0)-1)

      if debug then
        case str
          when "#dv"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:dv)
          when "#dc"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:dc)
          when "#dl"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:dl)
          when "#dr"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:dr)
        end
      end
    end
  end

  def do_debug_flag(index)
    @debug_flags[index].each do |flag|
      print "#" + flag.to_s + " "
      case flag
        when :dv then puts @current_value
        when :dc then
          print @active_stack == @left ? "(left) " : "(right) "
          puts @active_stack.inspect_array
        when :dl then puts @left.inspect_array
        when :dr then puts @right.inspect_array
      end
    end
  end

  def step()
    if @running == false then
      return false
    end
    if @last_op == :nilad then
      do_debug_flag(@index-1)
    end
    if @last_op != :close_curly then
      do_debug_flag(@index)
    end
    current_symbol = @source[@index..@index+1] or @source[@index]
    if ['()', '[]', '{}', '<>'].include? current_symbol
      case current_symbol
        when '()' then @current_value += 1
        when '[]' then @current_value -= 1
        when '{}' then @current_value += @active_stack.pop
        when '<>' then @active_stack = @active_stack == @left ? @right : @left
      end
      @last_op = :nilad
      @index += 2
    else
      @last_op = :monad
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
        raise BrainFlakError.new("Unmatched " + current_symbol, @index + 1) if data == nil
        raise BrainFlakError.new("Mismatched closing bracket %s. Expected to close %s at character %d" % [current_symbol, data[0], data[2] + 1], @index + 1) if not brackets_match?(data[0], current_symbol)

        case current_symbol
          when ')' then @active_stack.push(@current_value)
          when ']' then puts @current_value
          when '>' then @current_value = 0
          when '}'
            if @active_stack.peek != 0 then
              @index = data[2] - 1
              @last_op = :close_curly
            end
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
