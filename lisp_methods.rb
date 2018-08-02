module LispMethods
  def replace_sym(obj, sym, value)
    if !obj.is_a?(Array)
      obj == sym ? value : obj
    else
      obj.map do |elem|
        replace_sym(elem, sym, value)
      end
    end
  end

  def sublis(array, map)
    map.each do |sym, value|
      array = replace_sym(array, sym, value)
    end
    array
  end

  def rest_of_arr(arr)
    arr[1..-1] || []
  end
end
