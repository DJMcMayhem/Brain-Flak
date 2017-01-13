require_relative './BrainFlakError.rb'

class Stack
  def initialize(name)
    @name = name
    @data = []
  end

  attr_reader :data

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

  def print_stack(ascii_mode, reverse)
    (reverse ? @data: @data.reverse).each do |value|
      if ascii_mode
        begin
          print (value % 2 ** 32).chr(Encoding::UTF_8)
        rescue RangeError => ex
          #Error at character 0 is probably not right but I can't access the proper location from here
          raise BrainFlakError.new("Value #{value} is out of range for UTF_8 encoding.",0)
        end
      else
        print value.to_s + "\n"
      end
    end
	print "\n" if ascii_mode
    STDOUT.flush
  end

  def talk
    puts @name
  end

  def inspect_array
    return @data.inspect
  end

  def char_inspect_array(n)
    return @data.map {|a| (a%n).chr(Encoding::UTF_8)}.join("")
  end

  def height
    return @data.length
  end

  def at(index)
    return @data.at(index)
  end

  def get_data
    return @data
  end

  def set_data(data)
    @data = data
  end
end

def is_opening_bracket?(b)
  if b != nil then
    return '([{<'.include? b
  end
end

def is_closing_bracket?(b)
  if b != nil then
    return ')]}>'.include? b
  end
end

def brackets_match?(b1, b2)
  s = [b1, b2].join('')
  return ['()', '[]', '{}', '<>'].include? s
end

