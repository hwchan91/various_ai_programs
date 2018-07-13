require 'pry'

class PatternMatcher
  attr_accessor :pattern, :string

  SINGLE_PATTERNS = {
    '?|' => 'match_or',  # ?|=[1,2,3]
    '?=' => 'match_is',  # ?=[?N, :is_a?, Numeric], ?=[?N, :odd?]
    '?&' => 'match_and', # ?&[ ?=[?N, :is_a?, Numeric], ?=[?N, :odd?] ]
    '?!' => 'match_not', # ?!(?X)
  }
  SEGMENT_PATTERNS = {
    '?*' => 'segment_match', # ?*(?X)
    '?+' => 'segment_match_one_plus', # ?+(?X)
    '??' => 'segment_match_zero_or_one' # ??(?X)
  }

  def initialize(opt = {})
    @pattern_arr         = opt[:pattern].scan(/\S+/)
    @string_arr          = opt[:string].scan(/\S+/)
  end

  def solve
    pattern_matcher(@pattern_arr, @string_arr)
  end

  def pattern_matcher(pattern_arr, string_arr, bindings = {})
    return bindings if pattern_arr.nil? || pattern_arr.empty?
    return fail if bindings == fail

    sym = pattern_arr.first
    if is_variable?(sym)
      bindings = update_bindings(sym, first_of_string(string_arr), bindings)

    # elsif single_pattern(sym)
    #   return unless bindings = single_matcher(sym, string_arr.shift, bindings)
    #   pattern_matcher(pattern_arr, string_arr, bindings)
    elsif segment_pattern(sym)
      return send(segment_pattern(sym), sym, pattern_arr[1..-1], string_arr, bindings)
    else
      return fail unless sym == first_of_string(string_arr)
    end
    pattern_matcher(pattern_arr[1..-1], string_arr[1..-1], bindings)
  end

  def first_of_string(string_arr)
    return unless string_arr
    string_arr.first
  end

  def fail
    nil
  end

  def update_bindings(var, input, bindings)
    bindings = bindings.dup
    input = input.join(" ") if input.is_a? Array
    return fail if bindings[var] && bindings[var] != input
    bindings[var] = input
    bindings
  end

  def is_variable?(sym)
    sym[/^\?[a-zA-Z]+$/]
  end

  def single_pattern(sym)
    SINGLE_PATTERNS[sym[0..1]]
  end

  def segment_pattern(sym)
    SEGMENT_PATTERNS[sym[0..1]]
  end

  def get_var_from_sym(sym)
    sym[3..-2]
  end

  def segment_match(sym, pattern_arr, string_arr, bindings, min_words: 0, max_words: nil)
    var = get_var_from_sym(sym)
    return update_bindings(var, string_arr, bindings) if pattern_arr.nil? || pattern_arr.empty?

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

  def segment_match_one_plus(sym, pattern_arr, string_arr, bindings)
    segment_match(sym, pattern_arr, string_arr, bindings, min_words: 1)
  end

  def segment_match_zero_or_one(sym, pattern_arr, string_arr, bindings)
    segment_match(sym, pattern_arr, string_arr, bindings, max_words: 1)
  end
end

pattern = "?*(?X) is ?*(?Y) is ?*(?X) is ?*(?Z)"
string = "B is C is D is B is C is E"

pattern = "?*(?X) is ?*(?Y) is ?*(?X)"
string = "B is C is D is B is C"

pattern = "A ?+(?X) ??(Y) ?*(?Z) ??(Y) ?+(?X) D"
string = "A B C E F E F B C D"

PatternMatcher.new(pattern: pattern, string: string).solve
