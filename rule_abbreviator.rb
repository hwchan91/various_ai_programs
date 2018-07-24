module RuleAbbreviator
  def expand_rules(rules)
    rules.map do |rule|
      rule_patterns = rule[:pattern].is_a?(Array) ? rule[:pattern] : [ rule[:pattern] ]
      rule_patterns.map! do |pattern|
        pattern = pattern.split(" ") if pattern.is_a?(String)
        expand_abbrev(pattern)
        pattern
      end

      rule[:pattern] = rule_patterns
      rule
    end
  end

  def expand_abbrev(pattern)
    $pat_abbrev.each do |abbrev, expansion|
      pattern.map! { |sym| sym == abbrev ? expansion : sym }
    end
  end

  def add_pat_abbrev(pattern:, expansion:)
    $pat_abbrev ||= {}
    $pat_abbrev[pattern] = expansion
  end
end
