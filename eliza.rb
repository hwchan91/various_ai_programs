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
    regex = Regexp.new(regex_string, "i")
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

class Eliza
  class << self
    attr_accessor :eliza_rules

    def run
      puts "say 'hello'"
      loop do
        puts generate_response(gets.chomp)
      end
    end

    def generate_response(input)
      variable_map, response = nil, nil
      rule = eliza_rules.find do |rule|
        variable_map = PatternChecker.new(pattern: rule[:pattern], string: input).solve
      end

      return "Sorry, I don't understand you" unless rule
      response = rule[:responses].sample.dup
      variable_map.map!{ |variable, value| [variable, switch_viewpoint(value)] }
      variable_map.each do |variable, value|
        response.gsub!(variable, value)
      end
      response
    end

    def switch_viewpoint(value)
        words = value.scan(/\w+/)
        words.map! do |word|
          case word.downcase
          when 'i' then 'you'
          when 'you' then 'i'
          when 'me' then 'you'
          when 'am' then 'are'
          when 'my' then 'your'
          when 'your' then 'my'
          when 'mine' then 'yours'
          when 'yours' then 'mine'
          else word
          end
        end
        words.join(" ").gsub("i are", "i am")
    end
  end

  @eliza_rules = [
    {
      pattern: "?X hello ?Y",
      responses: ["How do you do. Please state your problem."]
    },
    {
      pattern: "?X I want ?Y",
      responses: ["What would it mean if you got ?Y?", "Why do you want ?Y?", "Suppose you got ?Y soon"]
    },
    {
      pattern: "?X I don't want ?Y",
      responses: ["What do you want then?"]
    },
    {
      pattern: "?X if ?Y",
      responses: ["Do you really think its likely that ?Y?", "Do you wish that ?Y?", "What do you think about ?Y?", "Really-- if ?Y"]
    },
    {
      pattern: "?X no ?Y",
      responses: ["Why not?", "You are being a bit negative", "Are you saying NO just to be negative?"]
    },
    {
      pattern: "?X I was ?Y",
      responses: ["Were you really?", "Perhaps I already knew you were ?Y", "Why do you tell me you were ?Y now?"]
    },
    {
      pattern: "?X I feel ?Y",
      responses: ["Do you often feel ?Y?"]
    },
    {
      pattern: "?X I felt ?Y",
      responses: ["What other feelings do you have?"]
    },
    {
      pattern: "?X You are ?Y",
      responses: ["What made you think I am ?Y?"]
    }
  ]
end
