
class DebugFlag
  def initialize(name, data)
    @name = name
    if /'.'/.match(data) then
      @data = data[1].ord
    elsif /\d+/.match(data) then
      @data = data.to_i
    elif data = "" then
      @data = 0
    else
      raise BrainFlakError.new("Parsing Error (This should not happen)",0)
    end
  end
  def to_s
    return @name
  end
  def get_data
    return @data
  end
end
