# version create by myself using regex

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
    regex_string = @pattern.sub(/\s?\?\w+\s?/, '(.*)').gsub(/\s?\?\w+\s?/, '($|\s.*)').gsub(' ', '\s') # beyond the first variable, all variables needs to be preceded by a space
    regex = Regexp.new(regex_string, "i")
  end

  def extract_variables_from_pattern
    @pattern.scan(/\?\w+/)
  end

  def find_values
    indices_of_spaces = (0...@string.length).find_all { |i| @string[i] == ' ' } + [@string.length-1]

    indices_of_spaces.each do |index|
      values = @string[0..index].scan(@regex).first
      next unless values

      values[-1] += @string[index+1..-1]
      values.map!{ |val| val.strip }
      next if @possible_values.include?(values)

      @possible_values << values
    end

    return unless @possible_values.any?
    @possible_values
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

pattern = "?X hello ?Y"
string = "hello to you"

PatternChecker.new(pattern: pattern,string: string).solve

pattern = "?X I need ?Y"
string = "I need you"

PatternChecker.new(pattern: pattern,string: string).solve

pattern = "?X is a ?Y is a ?Z is a ?Y"
string = "1 is a 2 3 is a 1 is a 2 3"

PatternChecker.new(pattern: pattern,string: string).solve

pattern = "?X is a ?X"
string = "1 is a 2 3 is a 1 is a 2 3"

PatternChecker.new(pattern: pattern,string: string).solve

pattern = "?X is a ?X"
string = "1 is a 2 3 is a 1 is a 2 3 4"

PatternChecker.new(pattern: pattern,string: string).solve

pattern = "?X is a ?Y"
string = "1 is a 2 3 4"

PatternChecker.new(pattern: pattern,string: string).solve
