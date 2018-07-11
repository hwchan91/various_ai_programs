require 'pry'

class PatternMatcher
  attr_accessor :pattern, :string

  SINGLE_PATTERNS = {
    '?|' => 'match-or',  # ?|=[1,2,3]
    '?=' => 'match-is',  # ?=[?N, :is_a?, Numeric], ?=[?N, :odd?]
    '?&' => 'match-and', # ?&[ ?=[?N, :is_a?, Numeric], ?=[?N, :odd?] ]
    '?!' => 'match-not', # ?!(?X)
  }
  SEGMENT_PATTERNS = {
    '?*' => 'segment-match', # ?*(?X)
    '?+' => 'segment-match-one-plus', # ?+(?X)
    '??' => 'segment-match-zero-or-one' # ??(?X)
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
      return segment_matcher(sym, pattern_arr[1..-1], string_arr, bindings)
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
    puts bindings
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

  def segment_matcher(sym, pattern_arr, string_arr, bindings)
    var = get_var_from_sym(sym)
    return update_bindings(var, string_arr, bindings) if pattern_arr.nil? || pattern_arr.empty?

    indices = string_arr.each_index.select{ |i| string_arr[i] == pattern_arr.first }
    return fail unless indices.any?

    result_bindings = {}
    index = indices.find do |index|
      next unless new_bindings = update_bindings(var, string_arr[0..index-1], bindings)
      result_bindings = pattern_matcher(pattern_arr, string_arr[index..-1], new_bindings)
    end
    return fail unless index
    result_bindings
  end
end

pattern = "?*(?X) is ?*(?Y) is ?*(?X) is ?*(?Z)"
string = "B is C is D is B is C is E"

PatternMatcher.new(pattern: pattern, string: string).solve
