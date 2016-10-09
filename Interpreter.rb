require 'io/console'
require_relative './stack.rb'
require_relative './Flag.rb'

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

  attr_accessor :current_value, :active_stack
  attr_reader :running, :left, :right, :main_stack

  def initialize(source, left_in, right_in, debug)
    # Strip comments
    source = source.gsub(/(^[^#]*)#.*(\n|$)/, '\1')
    # Strips the source of any characters that aren't brackets or part of debug flags
    @source = source.gsub(/(?<=[()\[\]<>{}])[^@()\[\]<>{}]*/, "")
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
    while match = /@[^@()\[\]{}<>]+/.match(@source) do
      str = @source.slice!(match.begin(0)..match.end(0)-1)
      slicer = /@[^'\d]*/.match(str)
      flag = str.slice(1..slicer.end(0)-1)
      data = str.slice(slicer.end(0)..-1)
      if /(\d*|'.')/.match(data).end(0) != data.length then
        raise BrainFlakError.new("Invalid data, %s, in flag, @%s" % [data,flag],match.begin(0))
      end
      @debug_flags[match.begin(0)] = @debug_flags[match.begin(0)].push(DebugFlag.new(flag,data))
    end
  end

  def do_debug_flag(index)
    @debug_flags[index].each do |flag|
      STDERR.print "@%s " % flag.to_s
      case flag.to_s
        when "dv" then STDERR.puts @current_value
        when "av" then STDERR.puts (@current_value%256).chr(Encoding::UTF_8)
        when "uv" then STDERR.puts (@current_value%2**32).chr(Encoding::UTF_8)
        when "dc","ac","uc" then
          print @active_stack == @left ? "(left) " : "(right) "
          case flag.to_s
            when "dc" then
              STDERR.puts @active_stack.inspect_array
            when "ac" then
              STDERR.puts @active_stack.char_inspect_array(256)
            when "uc" then
              STDERR.puts @active_stack.char_inspect_array(2**32)
          end
        when "dl" then STDERR.puts @left.inspect_array
        when "al" then STDERR.puts @left.char_inspect_array(256)
        when "ul" then STDERR.puts @left.char_inspect_array(2**32)
        when "dr" then STDERR.puts @right.inspect_array
        when "ar" then STDERR.puts @right.char_inspect_array(256)
        when "ur" then STDERR.puts @right.char_inspect_array(2**32)
        when "df" then
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
            builder += " "*(max_left+1) + "^\n"
          end
          STDERR.puts builder
        when "af","uf" then
          case flag.to_s
            when "af" then limit=256
            when "uf" then limit=2**32
          end
          builder = @active_stack == @left ? "^\n" : "  ^\n"
          for i in 0..[@left.height,@right.height].max do
            c_right = (@right.at(i) != nil ? @right.at(i) : 32)%limit
            c_left  = (@left.at(i)  != nil ? @left.at(i)  : 32)%limit
            builder = (c_left.chr(Encoding::UTF_8)).ljust(2) + c_right.chr(Encoding::UTF_8) + "\n" + builder
          end
          STDERR.puts builder
       when "cy" then STDERR.puts @cycles
       when "ij" then
         injection = $stdin.read
         STDERR.puts
         sub_interpreter = BrainFlakInterpreter.new(injection, @left.get_data, @right.get_data, true)
         sub_interpreter.active_stack = @active_stack == @left ? sub_interpreter.left : sub_interpreter.right
         sub_interpreter.current_value = @current_value
         begin
           while sub_interpreter.step
           end
           if sub_interpreter.main_stack.length > 0
            unmatched_brak = sub_interpreter.main_stack[0]
            raise BrainFlakError.new("Unclosed '%s' character." % unmatched_brak[0], unmatched_brak[2])
           end
         rescue Interrupt
           STDERR.puts "\nKeyboard Interrupt"
           STDERR.puts sub_interpreter.inspect
           raise "Second Interrupt"
         rescue RuntimeError => e
           if e.to_s == "Second Interrupt" then
             STDERR.puts sub_interpreter.inspect
           end
           raise e
         end
         @left.set_data(sub_interpreter.left.get_data)
         @right.set_data(sub_interpreter.right.get_data)
         @active_stack = sub_interpreter.active_stack == sub_interpreter.left ? @left : @right
         @current_value = sub_interpreter.current_value
      when "dh" then STDERR.puts @active_stack.height
      when "lt" then 
        print "\n"
        @current_value += flag.get_data
      end
      STDERR.flush
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
