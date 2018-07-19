module RuleAbbreviator
  def expand_rules(rules)
    rules.each do |rule|
      rule_vars = rule[:pattern].is_a?(Array) ? rule[:pattern] : [ rule[:pattern] ]
      rule_vars.each do |var|
        expand_abbrev(var)
      end
    end
  end

  def expand_abbrev(string)
    $pat_abbrev.each do |abbrev, expansion|
      string.gsub!(abbrev, expansion)
    end
  end

  def add_pat_abbrev(pattern:, expansion:)
    $pat_abbrev ||= {}
    $pat_abbrev[pattern] = expansion
  end
end
