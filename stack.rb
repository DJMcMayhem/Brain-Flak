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

  def inspect_array
    return @data.inspect
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

