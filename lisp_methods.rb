module LispMethods
  def sublis(obj, sym, value)
    if !obj.is_a?(Array)
      obj == sym ? value : obj
    else
      obj.map do |elem|
        sublis(elem, sym, value)
      end
    end
  end
end
