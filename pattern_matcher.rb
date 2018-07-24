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
    sym && sym.class != Array && SINGLE_PATTERNS[sym[0..1]]
  end

  def segment_pattern(pattern)
    return unless pattern.class == Array
    sym = pattern.first
    sym && SEGMENT_PATTERNS[sym[0..1]]
  end

  def get_var_from_segment_sym(sym)
    sym[3..-2]
  end

  def segment_match(pattern_arr, string_arr, bindings, min_words: 0, max_words: nil)
    var = get_var_from_segment_sym(pattern_arr.shift)
    return update_bindings(var, string_arr, bindings) if pattern_arr.empty?

    result_bindings = {}
    index = ((min_words - 1) ... [string_arr.length, max_words].compact.min ).find do |index|
      next unless new_bindings = update_bindings(var, get_subarray(string_arr, index), bindings)
      result_bindings = pattern_matcher(pattern_arr, string_arr[index+1..-1], new_bindings)
    end
    return fail unless index
    result_bindings
  end

  def get_subarray(string_arr, index)
    index < 0 ? [] : string_arr[0..index]
  end

  def segment_match_one_plus(pattern_arr, string_arr, bindings)
    segment_match(pattern_arr, string_arr, bindings, min_words: 1)
  end

  def segment_match_zero_or_one(pattern_arr, string_arr, bindings)
    segment_match(pattern_arr, string_arr, bindings, max_words: 1)
  end

  def get_arr_from_sym(sym)
    split_outer_commas(get_var_from_segment_sym(sym))
  end

  def match_is(pattern, value, bindings)
    arr = get_arr_from_sym(pattern)
    var, cond = arr.first, arr.last
    return fail unless eval(cond)
    update_bindings(var, value, bindings)
  end

  def match_or(pattern, string, bindings)
    options = get_arr_from_sym(pattern)
    new_bindings = {}
    options.find do |pattern|
      new_bindings = pattern_matcher(pattern, string, bindings)
    end
    new_bindings
  end

  def match_and(pattern, string, bindings)
    options = get_arr_from_sym(pattern)
    new_bindings = {}
    options.all? do |pattern|
      new_bindings = pattern_matcher(pattern, string, bindings)
    end
    new_bindings
  end

  def match_not(pattern, string, bindings)
    reject_options = get_arr_from_sym(pattern).map{ |val| get_value(val, bindings) }
    return fail if reject_options.include?(string)
    bindings
  end

  def get_value(val, bindings)
    return val unless is_variable?(val)
    bindings[val]
  end

  def split_outer_commas(string)
    indexes = []
    scoped_count = 0
    string.split("").each_with_index do |char, index|
      scoped_count += 1 if char == '['
      scoped_count -= 1 if char == ']'
      indexes << index if char == ',' && scoped_count == 0
    end

    start_indexes = [0] + indexes.map{|i| i+1}
    end_indexes = indexes.map{|i| i-1} + [-1]
    index_pairs = start_indexes.zip(end_indexes)
    arr = []
    index_pairs.each do |start_index, end_index|
      arr << string[start_index..end_index]
    end
    arr
  end

  def is_i?(value)
    value =~ /\A[-+]?[0-9]+\z/
  end
end


# pattern = "?*(?X) is ?*(?Y) is ?*(?X) is ?*(?Z)"
# string = "B is C is D is B is C is E"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = [ %w(?* ?X), 'is', %w(?* ?Y), 'is', %w(?* ?X), 'is', %w(?* ?Z) ]
# string = %w(B is C is D is B is C is E)
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "?*(?X) is ?*(?Y) is ?*(?X)"
# string = "B is C is D is B is C"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "A ?+(?X) ??(Y) ?*(?Z) ??(Y) ?+(?X) D"
# string = "A B C E F E F B C D"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "A ?=[?B,is_i?(value)]"
# string = "A 12"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "?X ?|[<,=,>] ?Y"
# string = "3 < 4"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "?X =/= ?![<,=,?X]"
# string = "3 =/= 4"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "A ?&[?=[?B,is_i?(value)],?|[?=[?B,value.to_i<5],?=[?B,value.to_i>20]]]"
# string = "A 35"
# PatternMatcher.new(pattern: pattern, string: string).solve

# pattern = "?*(?X) B C"
# string = "A B C D"
# PatternMatcher.new(pattern: pattern, string: string).solve

# binding.pry
