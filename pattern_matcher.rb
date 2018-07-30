require 'pry'

class PatternMatcher
  attr_accessor :pattern, :string

  SINGLE_PATTERNS = {
    '?|' => 'match_or',  # ?|=[1,2,3]
    '?=' => 'match_is',  # ?=[?N,value.is_a?(Numeric)], ?=[?N,value.odd?]
    '?&' => 'match_and', # ?&[ ?=[?N,value.is_a?(Numeric)], ?=[?N,value.odd?] ]
    '?!' => 'match_not', # ?![?X,2,3]
  }
  SEGMENT_PATTERNS = {
    '?*' => 'segment_match', # ?*(?X)
    '?+' => 'segment_match_one_plus', # ?+(?X)
    '??' => 'segment_match_zero_or_one' # ??(?X)
  }

  def initialize(opt = {})
    @pattern_arr = format_as_array(opt[:pattern])
    @string_arr  = format_as_array(opt[:string])
    @from_end    = opt[:from_end] || false
  end

  def format_as_array(words)
    return words if words.is_a?(Array)
    words.scan(/\S+/)
  end

  def solve
    pattern_matcher(@pattern_arr, @string_arr)
  end

  def pattern_matcher(pattern, string, bindings = {})
    return fail if bindings == fail

    if is_variable?(pattern)
      return update_bindings(pattern, string, bindings)
    elsif pattern == string
      return bindings
    elsif single_pattern(pattern)
      return send(single_pattern(pattern), pattern, string, bindings)
    elsif segment_pattern(pattern)
      return send(segment_pattern(pattern), pattern, string, bindings)
    elsif pattern.class == Array && string.class == Array
      new_bindings = pattern_matcher(pattern.first, string.first, bindings)
      pattern_matcher(rest_of_arr(pattern), rest_of_arr(string), new_bindings)
    else
      fail
    end
  end

  def rest_of_arr(arr)
    arr[1..-1] || []
  end

  def fail
    nil
  end

  def update_bindings(var, input, bindings)
    bindings = bindings.dup
    return fail if bindings[var] && bindings[var] != input
    bindings[var] = input
    bindings
  end

  def is_variable?(sym)
    sym && sym.class != Array && sym[/^\?[a-zA-Z]+$/]
  end

  def single_pattern(sym)
    sym && sym.class == Array && SINGLE_PATTERNS[sym.first]
  end

  def segment_pattern(pattern)
    return unless pattern.class == Array
    sym = pattern.first
    sym && sym.class == Array && SEGMENT_PATTERNS[sym.first]
  end

  def segment_match(pattern_arr, string_arr, bindings, min_words: 0, max_words: nil)
    pattern_arr = pattern_arr.dup
    segment_sym = pattern_arr.shift
    _, var, cond = segment_sym

    if pattern_arr.empty? && string_arr.size >= min_words
      return fail unless cond.nil? || eval_cond(var, string_arr, cond, bindings)
      return update_bindings(var, string_arr, bindings)
    end

    result_bindings = {}
    test_indexes = ((min_words - 1) ... [string_arr.length, max_words].compact.min).to_a
    test_indexes.reverse! if @from_end
    index = test_indexes.find do |index|
      value = get_subarray(string_arr, index)
      next unless eval_cond(var, value, cond, bindings)
      next unless new_bindings = update_bindings(var, value, bindings)
      result_bindings = pattern_matcher(pattern_arr, string_arr[index+1..-1], new_bindings)
    end
    return fail unless index
    result_bindings
  end

  def get_subarray(string_arr, index)
    index < 0 ? [] : string_arr[0..index]
  end

  def eval_cond(var, value, cond, bindings)
    return true if cond.nil?
    cond = cond.dup
    cond.gsub!(var, 'value')
    var_in_cond = cond.scan(/\?\w+/)
    var_in_cond.each { |v| cond.gsub!(v, "bindings['#{v}']") }
    eval(cond)
  end

  def segment_match_one_plus(pattern_arr, string_arr, bindings)
    segment_match(pattern_arr, string_arr, bindings, min_words: 1)
  end

  def segment_match_zero_or_one(pattern_arr, string_arr, bindings)
    segment_match(pattern_arr, string_arr, bindings, max_words: 1)
  end

  def match_is(pattern, value, bindings)
    _, var, cond = pattern
    return fail unless eval_cond(var, value, cond, bindings)
    update_bindings(var, value, bindings)
  end

  # can be replaced by match_is
  def match_or(pattern, string, bindings)
    _, options = pattern[0], pattern[1]
    new_bindings = {}
    options.find do |pattern|
      new_bindings = pattern_matcher(pattern, string, bindings)
    end
    new_bindings
  end

  # can be replaced by match_is
  def match_and(pattern, string, bindings)
    _, options = pattern[0], pattern[1]
    new_bindings = {}
    options.all? do |pattern|
      new_bindings = pattern_matcher(pattern, string, bindings)
    end
    new_bindings
  end

  # can be replaced by match_is
  def match_not(pattern, string, bindings)
    _, reject_options = pattern[0], pattern[1].map{ |val| get_value(val, bindings) }
    return fail if reject_options.include?(string)
    bindings
  end

  def get_value(val, bindings)
    return val unless is_variable?(val)
    bindings[val]
  end

  def is_i?(value)
    return true if value.is_a?(Numeric)
    value =~ /\A[-+]?[0-9]+\z/
  end
end


# pattern = [ %w(?* ?X), 'is', %w(?* ?Y), 'is', %w(?* ?X), 'is', %w(?* ?Z) ]
# string = %w(B is C is D is B is C is E)
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern =  [ %w(?* ?X), 'is', %w(?* ?Y), 'is', %w(?* ?X) ]
# string = %w(B is C is D is B is C)
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = ["A",  %w(?+ ?X), %w(?? ?Y), %w(?* ?Z), %w(?? ?Y), %w(?+ ?X), "D" ]
# string = %w(A B C E F E F B C D)
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = ["A", %w(?= ?B is_i?(?B))]
# string = ["A", 12]
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = ["?X", ["?|", %w(< = >) ], "?Y"]
# string = "3 < 4"
# PatternMatcher.new(pattern: pattern, string: string).solve
# pattern = ["?X", ["?=", "?Y", "%w(< = >).include?(?Y)"], "?Z"]
# string = "3 < 4"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = ["?X", "=/=", ["?!", %w(< = ?X)] ]
# string = "3 =/= 4"
# PatternMatcher.new(pattern: pattern, string: string).solve
# pattern = ["?X", "=/=", ["?=", "?Y", "?Y != ?X"] ]
# string = "3 =/= 4"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = [ "A", ["?&", [ %w(?= ?B is_i?(value)) , ["?|", [ %w(?= ?B value.to_i<5), %w(?= ?B value.to_i>20) ] ] ] ] ]
# string = "A 35"
# PatternMatcher.new(pattern: pattern, string: string).solve
# pattern = [%w(?* ?Y),  %w(?= ?X is_i?(?X)&&(?X.to_i<5||?X.to_i>20)) ]
# string = "10 15 35"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = [ %w(?* ?X), "B", "C"]
# string = "A B C D"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = [ "B", "C", %w(?+ ?X)]
# string = "B C"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern =  [["?+", "?X", "?X.last != 'B'"], "C", "D"]
# string = "A B D C D"
# PatternMatcher.new(pattern: pattern, string: string).solve



# binding.pry
