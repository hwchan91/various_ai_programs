### alternative method, does not accomodate -ve var, e.g '-2' or '--2'
def valid_equation?(equation)
  return if equation.scan(/=/).count > 1
  return unless equation =~ /^(\(*\s*\w+\s*\)*((\s*(\+|\-|\*|\/|\=)\s*)))*\(*\w+\)*$/

  while equation[0] == "(" && equation[-1] == ")"
    equation = equation[1..-2]
  end

  expressions = equation.split("=")
  expressions.none? do |exp|
    invalid = false
    parentheses = exp.scan(/\(|\)/)
    open_parentheses_count = parentheses.select { |sym| sym == "(" }.count
    invalid = true unless open_parentheses_count == parentheses.count / 2

    level_count = 0
    parentheses.each do |sym|
      next if invalid
      level_count += 1 if sym == "("
      level_count -= 1 if sym == ")"
      invalid = true if level_count < 0
    end
    invalid
  end
end
