require_relative './BrainFlakError.rb'

def braceCheck(source)
  matches = ["()","[]","<>","{}"]
  stack = []
  checking = true
  source.split("").each_with_index do |char, i|
    if char == "#"
      checking = false
    elsif char == "\n"
      checking = true
    end

    if not checking
      true #Do nothing
    elsif "([<{".include? char
      stack.push([char, i])
    elsif ")]>}".include? char
      if stack.empty?
        raise BrainFlakError.new("Unopened '%s' character." %  char,i)
      elsif matches.include? stack[-1][0]+char
        stack.pop
      else
        raise BrainFlakError.new("Expected to close '%s' from location %s but instead encountered '%s'." % [stack[-1][0],stack[-1][1],char], i)
      end
    end
  end
  if not stack.empty? 
    raise BrainFlakError.new("Unclosed '%s' character." % stack[-1][0],stack[-1][1])
  end
end
