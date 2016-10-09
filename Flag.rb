
class DebugFlag
  def initialize(name, data)
    @name = name
    if /'.'/.match(data) then
      @data = data[1].ord
    else
      @data = data.to_i
    end
  end
  def to_s
    return @name
  end
end
