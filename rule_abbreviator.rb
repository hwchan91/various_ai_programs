module RuleAbbreviator
  def expand_rules(rules)
    rules.each do |rule|
      rule[:pattern] = rule[:pattern].is_a?(Array) ? rule[:pattern] : [ rule[:pattern] ]
      rule[:pattern].map! do |pattern|
        pattern = pattern.split(" ") if pattern.is_a?(String)
        expand_abbrev(pattern)
      end
    end
  end

  def expand_abbrev(arr)
    arr.map do |sym|
      if sym.is_a? Array
        expand_abbrev(sym)
      else
        convert_abbrev(sym)
      end
    end
  end

  def convert_abbrev(sym)
    if $pat_abbrev.keys.any? { |abb| abb == sym }
      $pat_abbrev[sym]
    else
      sym
    end
  end

  def add_pat_abbrev(pattern:, expansion:)
    $pat_abbrev ||= {}
    $pat_abbrev[pattern] = expansion
  end
end
