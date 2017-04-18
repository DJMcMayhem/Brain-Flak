require 'io/console'
require_relative './stack.rb'
require_relative './Flag.rb'
require_relative './BrainFlakError.rb'
require_relative './Interpreter.rb'

class BrainFlueueInterpreter < Interpreter

  # Nilads ~~~~~~~~~~~~~~~~~~~~~
 
  def round_nilad()
    @current_value += 1
  end

  def square_nilad()
    @current_value += @active_stack.height
  end

  def curly_nilad()
    @current_value += @active_stack.pop
  end

  def angle_nilad()
    @active_stack = @active_stack == @left ? @right : @left
  end

  # Open Braces ~~~~~~~~~~~~~~~~

  def open_round()
    @main_stack.push(['(', @current_value, @index])
    @current_value = 0
  end

  def open_square()
    @main_stack.push(['[', @current_value, @index])
    @current_value = 0
  end

  def open_curly()
    @main_stack.push(['{', 0, @index])
    new_index = read_until_matching(@source, @index)
    raise BrainFlakError.new("Unmatched '{' character", @index + 1) if new_index == nil
    if not active_stack.data.first then
      @main_stack.pop()
      @index = new_index
    end
  end

  def open_angle()
    @main_stack.push(['<', @current_value, @index])
    @current_value = 0
  end

  # Close Braces ~~~~~~~~~~~~~~~

  def close_round()
    data = @main_stack.pop()
    raise BrainFlakError.new("Unmatched '" + @source[@index] + "' character", @index + 1) if data == nil
    raise BrainFlakError.new("Expected to close '%s' from location %d but instead encountered '%s' " % [data[0] , data[2] + 1, @source[@index]], @index + 1) if not brackets_match?(data[0], @source[@index])
    @active_stack.data.unshift(@current_value)
    @current_value += data[1]
  end

  def close_square()
    data = @main_stack.pop()
    raise BrainFlakError.new("Unmatched '" + @source[@index] + "' character", @index + 1) if data == nil
    raise BrainFlakError.new("Expected to close '%s' from location %d but instead encountered '%s' " % [data[0] , data[2] + 1, @source[@index]], @index + 1) if not brackets_match?(data[0], @source[@index])
    @current_value *= -1
    @current_value += data[1]
  end

  def close_curly()
    data = @main_stack.pop()
    raise BrainFlakError.new("Unmatched '" + @source[@index] + "' character", @index + 1) if data == nil
    raise BrainFlakError.new("Expected to close '%s' from location %d but instead encountered '%s' " % [data[0] , data[2] + 1, @source[@index]], @index + 1) if not brackets_match?(data[0], @source[@index])
    if @active_stack.data.first then
      @index = data[2] - 1
      @last_op = :close_curly
    end
    @current_value += data[1]
  end

  def close_angle()
    data = @main_stack.pop()
    raise BrainFlakError.new("Unmatched '" + @source[@index] + "' character", @index + 1) if data == nil
    #Here I use @source[@index] I am not sure why but @current symbol always yields nothing
    raise BrainFlakError.new("Expected to close '%s' from location %d but instead encountered '%s' " % [data[0] , data[2] + 1, @source[@index]], @index + 1) if not brackets_match?(data[0], @source[@index])
    @current_value = data[1]
  end

end
