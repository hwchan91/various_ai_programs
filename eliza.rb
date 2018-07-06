require 'pry'

class PatternChecker
  attr_accessor :pattern, :string

  def initialize(opt = {})
    @pattern         = opt[:pattern]
    @string          = opt[:string]
    @regex           = pattern_to_regex
    @variable_seq    = extract_variables_from_pattern
    @possible_values = []
  end

  def solve
    return unless find_values
    get_variable_map
  end

  def pattern_to_regex
    regex_string = @pattern.gsub(/\s?\?\w+\s?/, '(.*)').gsub(' ', '\s')
    regex = Regexp.new(regex_string)
  end

  def extract_variables_from_pattern
    @pattern.scan(/\?\w+/)
  end

  def find_values
    test_string, rest_of_string = @string, ""

    loop do
      values = test_string.scan(@regex).first
      break unless values

      values.map!{ |val| val.strip }
      values[-1] += rest_of_string
      break if @possible_values.include?(values)

      @possible_values << values
      trim_index = string.index(Regexp.new("#{rest_of_string}$"))
      test_string, rest_of_string = string[0...trim_index], string[trim_index..-1]
    end
    return unless @possible_values.any?
    @possible_values.reverse!
  end

  def get_variable_map
    values = @possible_values.find do |values|
      variable_value_pairs = @variable_seq.zip(values)
      variable_value_pairs.uniq.count == @variable_seq.uniq.count
    end
    return unless values
    @variable_seq.zip(values).uniq
  end
end

# pattern = "?X hello ?Y"
# string = "hello"

# PatternChecker.new(pattern: pattern,string: string).solve

# pattern = "?X I need ?Y"
# string = "I need you"

# PatternChecker.new(pattern: pattern,string: string).solve

# pattern = "?X is a ?Y is a ?Z is a ?Y"
# string = "1 is a 2 3 is a 1 is a 2 3"

# PatternChecker.new(pattern: pattern,string: string).solve

# pattern = "?X is a ?X"
# string = "1 is a 2 3 is a 1 is a 2 3"

# PatternChecker.new(pattern: pattern,string: string).solve

# pattern = "?X is a ?X"
# string = "1 is a 2 3 is a 1 is a 2 3 4"

# PatternChecker.new(pattern: pattern,string: string).solve

# pattern = "?X is a ?Y"
# string = "1 is a 2 3 4"

# PatternChecker.new(pattern: pattern,string: string).solve
