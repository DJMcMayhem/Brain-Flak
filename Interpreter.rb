require 'io/console'
require_relative './stack.rb'

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

  attr_accessor :active_stack, :current_value
  attr_reader :running, :left, :right

  def initialize(source, left_in, right_in, debug)
    # Strips the source of any characters that aren't brackets or part of debug flags
    @source = source.gsub(/(?:(?<=[()\[\]{}<>])|\s|^)[^#()\[\]{}<>]*/, "")
    @left = Stack.new('Left')
    @right = Stack.new('Right')
    @main_stack = []
    @active_stack = @left
    @index = 0
    @current_value = 0
    # Hash.new([]) does not work since modifications change that original array
    @debug_flags = Hash.new{|h,k| h[k] = []}
    @last_op = :none
    @cycles = 0
    left_in.each do|a|
      @left.push(a)
    end
    right_in.each do|a|
      @right.push(a)
    end
    remove_debug_flags(debug)
    @running = @source.length > 0
    @run_debug = !@running && @debug_flags.size > 0
  end

  def inactive_stack
    return @active_stack == @left ? @right : @left
  end

  def remove_debug_flags(debug)
    while match = /#[^#()\[\]{}<>\s]*/.match(@source) do
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
          when "#df"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:df)
          when "#cy"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:cy)
          when "#ij"
            @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(:ij)
        end
      end
    end
  end

  def do_debug_flag(index)
    @debug_flags[index].each do |flag|
      print "#%s " % flag.to_s
      case flag
        when :dv then puts @current_value
        when :dc then
          print @active_stack == @left ? "(left) " : "(right) "
          puts @active_stack.inspect_array
        when :dl then puts @left.inspect_array
        when :dr then puts @right.inspect_array
        when :df then
          builder = ""
          if @left.height > 0 then
            max_left = @left.get_data.map { |item| item.to_s.length}.max
          else
            max_left = 1
          end
          for i in 0..[@left.height,@right.height].max do
            builder = @left.at(i).to_s.ljust(max_left+1) + @right.at(i).to_s + "\n" + builder
          end
          if @active_stack == @left then
            builder += "^\n"
          else
            builder += " "*(max_left+1) + "^"
          end
          puts builder+"\n"
       when :cy then puts @cycles
       when :ij then
         injection = $stdin.read
         puts
         sub_interpreter = BrainFlakInterpreter.new(injection, @left.get_data, @right.get_data, true)
         sub_interpreter.active_stack = @active_stack == @left ? sub_interpreter.left : sub_interpreter.right
         sub_interpreter.current_value = @current_value
         while sub_interpreter.running do
           sub_interpreter.step
         end
         @left.set_data(sub_interpreter.left.get_data)
         @right.set_data(sub_interpreter.right.get_data)
         @active_stack = sub_interpreter.active_stack == sub_interpreter.left ? @left : @right
         @current_value = sub_interpreter.current_value
      end
    end
  end

  def step()
    if @run_debug or @running then
      if @last_op == :nilad then
        do_debug_flag(@index-1)
      end
      if @last_op != :close_curly then
        do_debug_flag(@index)
      end
      @run_debug = false
    end
    if !@running then
      return false
    end
    @cycles += 1
    current_symbol = @source[@index..@index+1] or @source[@index]
    if ['()', '[]', '{}', '<>'].include? current_symbol
      case current_symbol
        when '()' then @current_value += 1
        when '[]' then @current_value += @active_stack.height
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
          @current_value = 0
        end

      elsif is_closing_bracket?(current_symbol) then
        data = @main_stack.pop
        raise BrainFlakError.new("Unmatched " + current_symbol, @index + 1) if data == nil
        raise BrainFlakError.new("Mismatched closing bracket %s. Expected to close %s at character %d" % [current_symbol, data[0], data[2] + 1], @index + 1) if not brackets_match?(data[0], current_symbol)

        case current_symbol
          when ')' then @active_stack.push(@current_value)
          when ']' then @current_value *= -1
          when '>' then @current_value = 0
          when '}'
            if @active_stack.peek != 0 then
              @index = data[2] - 1
              @last_op = :close_curly
            end
        end
        @current_value += data[1]
      else raise BrainFlakError.new("Invalid character '%s'." % current_symbol, @index + 1)
      end
      @index += 1
    end
    if @index >= @source.length then
      @running = false
      if @last_op == :nilad then
        do_debug_flag(@index-1)
      end
      do_debug_flag(@index)
    end
    return true
  end

  def finish
    if @main_stack.length > 0
      unmatched_brak = @main_stack[0]
      raise BrainFlakError.new("Unclosed '%s' character." % unmatched_brak[0], unmatched_brak[2])
    end
  end

  def debug_info
    source = String.new(str=@source)
    offset = 0
    return "Cycles: %1$d\n"\
           "Current value: %2$d\n"\
           "%6$s Left stack: %3$s\n"\
           "%7$sRight stack: %4$s\n"\
           "Execution stack: %5$p\n"\
             % [@cycles, @current_value, @left.inspect_array, @right.inspect_array, @main_stack, *@active_stack == @left ? ["> ", "  "] : ["  ", "> "]]
  end

  def inspect
    source = String.new(str=@source)
    index = @index
    offset = 0
    @debug_flags.each_pair do |k,v|
      v.each do |sym|
        source.insert(k + offset, "#%s" % sym.id2name);
        offset += sym.id2name.length + 1
        if k <= index then
          index += sym.id2name.length + 1
        end
      end
    end
    winWidth = IO.console.winsize[1]
    if source.length <= winWidth then
      return "%s\n%s" % [source, "^".rjust(index + 1)]
    elsif index < winWidth/2 then
      return "%s...\n%s" % [source[0..winWidth-4],"^".rjust(index + 1)]
    elsif source.length - index < winWidth/2 then
      return "...%s\n%s" % [source[-(winWidth-3)..-1],"^".rjust(winWidth-(source.length-index))]
    else
      return "...%s...\n%s" % [source[3+index-winWidth/2..winWidth/2+index-4],"^".rjust(winWidth/2+1)]
    end
  end
end
