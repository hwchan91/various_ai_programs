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

# pattern = "?X hello ?Y"
# string = "hello to you"

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
      puts "hello"
      loop do
        puts generate_response(transform(gets.chomp))
      end
    end

    def transform(input)
      input.downcase.gsub(",", "").gsub(".", "").gsub("i am", "I'm").gsub("cannot", "can't").gsub("do not", "don't")
    end

    def generate_response(input)
      variable_map, response = nil, nil
      rule = eliza_rules.find do |rule|
        if rule[:pattern].is_a?(Array)
          rule[:pattern].find do |pattern|
            variable_map = PatternChecker.new(pattern: pattern, string: input).solve
          end
        else
          variable_map = PatternChecker.new(pattern: rule[:pattern], string: input).solve
        end
      end

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
          when 'you' then 'I'
          when 'me' then 'you'
          when 'am' then 'are'
          when 'my' then 'your'
          when 'your' then 'my'
          when 'mine' then 'yours'
          when 'yours' then 'mine'
          else word
          end
        end
        words.join(" ").gsub("I are", "I am")
    end
  end

  @eliza_rules = [
    {
      pattern: ["?X fuck ?Y", "?X shit ?Y", "?X cunt ?Y"],
      responses: ["You seem angry", "Words cannot hurt me","What have I done to make you use such language?", "Same to you", "What made you behave so childishly?"]
    },
    {
      pattern: ["?X hello ?Y", "?X hi ?Y"],
      responses: ["How do you do. Please state your problem."]
    },
    {
      pattern: "?X computer ?Y",
      responses: ["Do computer worry you?", "What do you think about machines?", "Why do you mention computers?", "What do you think machines have to do with your problem?"]
    },
    {
      pattern: "?X name ?Y",
      responses: ["I'm not interested in names"]
    },
    {
      pattern: "?X sorry ?Y",
      responses: ["Please don't apologize", "Apologies are not necessary", "What feelings do you have when you apologize?"]
    },
    {
      pattern: "?X I remember ?Y",
      responses: ["Do you often think of %Y?", "Does thinking of ?Y bring anything else to mind?", "What else do you remember?", "Why do you recall ?Y right now?", "What in the present situation reminds you of ?Y?", "What is the connection between me and ?Y?"]
    },
    {
      pattern: "?X do you remember ?Y",
      responses: ["Do you think I would forget ?Y?", "Why do you think I should recall ?Y now?", "what about ?Y?", "You mention ?Y?"]
    },
    {
      pattern: "?X if ?Y",
      responses: ["Do you really think its likely that ?Y?", "Do you wish that ?Y?", "What do you think about ?Y?", "Really? if ?Y"]
    },
    {
      pattern: "?X I dreamt ?Y",
      responses: ["Really? ?Y?", "Have you ever fantacized ?Y while you were awake?", "Have you dreamt ?Y before?"]
    },
    {
      pattern: "?X my mother ?Y",
      responses: ["Who else in your family ?Y?", "Tell me more about your family"]
    },
    {
      pattern: "?X my father ?Y",
      responses: ["Your father?", "Does he influence you strongly?", "What else comes to mind when you think of your father?"]
    },
    {
      pattern: "?X dream about ?Y",
      responses: ["How do you feel about ?Y in reality?", "?X dream ?Y?", "What does this dream suggest to you?", "Do you dream often?", "What persons appear in your dream?", "Don't you believe that dream has to do with your problem?"]
    },
    {
      pattern: "?X I want ?Y",
      responses: ["What would it mean if you got ?Y?", "Why do you want ?Y?", "Suppose you got ?Y soon"]
    },
    {
      pattern: "?X I'm glad ?Y",
      responses: ["What have I helped you to be ?Y?", "What makes you happy just now?", "Can you explain why you are suddenly happy ?Y"]
    },
    {
      pattern: "?X I'm sad ?Y",
      responses: ["I am sorry to here you are depressed", "I'm sure it's not pleasant to be sad"]
    },
    {
      pattern: "?X are like ?Y",
      responses: ["What resemblance do you see between ?X and ?Y?"]
    },
    {
      pattern: "?X is like ?Y",
      responses: ["In what way is it that ?X is like ?Y?"]
    },
    {
      pattern: "?X alike ?Y",
      responses: ["In what way?", "What similarities are there?"]
    },
    {
      pattern: "?X same ?Y",
      responses: ["What other connections do you see?"]
    },
    {
      pattern: "?X I was ?Y",
      responses: ["Were you really?", "Perhaps I already knew you were ?Y", "Why do you tell me you were ?Y now?"]
    },
    {
      pattern: "?X was I ?Y",
      responses: ["What if you were ?Y?", "Do you think you were ?Y?", "What would it mean if you were ?Y?"]
    },
    {
      pattern: "?X I'm ?Y",
      responses: ["In what way are you ?Y?", "Do you want to be ?Y?"]
    },
    {
      pattern: "?X am I ?Y",
      responses: ["Do you believe you are ?Y?", "Would you want to be ?Y?", "You wish I would teel you you are ?Y?", "What would it mean if you were ?Y?"]
    },
    {
      pattern: "?X am ?Y",
      responses: ["Why do say AM?", "I don't understand that"]
    },
    {
      pattern: "?X are you ?Y",
      responses: ["Why are you interested in whether I am ?Y or not?", "Would you prefer if I weren't ?Y?", "Perhaps I am ?Y in your fantasies"]
    },
    {
      pattern: "?X you are ?Y",
      responses: ["What made you think I am ?Y?"]
    },
    {
      pattern: "?X because ?Y",
      responses: ["Is that the real reason?", "What other reason might there be?", "Does that reason seem to explain anything else?"]
    },
    {
      pattern: "?X were you ?Y",
      responses: ["Perhaps I was ?Y", "What do you think?", "What if I had been ?Y?"]
    },
    {
      pattern: "?X I can't ?Y",
      responses: ["Maybe you could ?Y now", "What if you could ?Y?"]
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
      pattern: "?X I ?Y you ?Z",
      responses: ["Perhaps in your fantasy we ?Y each other"]
    },
    {
      pattern: "?X why don't you ?Y",
      responses: ["Should you ?Y?", "Do you believe I don't ?Y?", "Perhaps I will ?Y in good time"]
    },
    {
      pattern: "?X yes ?Y",
      responses: ["You seem quite positive", "You seem sure", "I understand"]
    },
    {
      pattern: "?X no ?Y",
      responses: ["Why not?", "You are being a bit negative", "Are you saying NO just to be negative?"]
    },
    {
      pattern: "?X someone ?Y",
      responses: ["Can you be more specific?"]
    },
    {
      pattern: "?X everyone ?Y",
      responses: ["Surely not everyone?", "Can you think of anyone in particular?", "Who for example?", "You are thinking of a special person"]
    },
    {
      pattern: "?X always ?Y",
      responses: ["Can you think of a specific example?", "When?", "What incident are you thinking of?", "Really? Always?"]
    },
    {
      pattern: "?X what ?Y",
      responses: ["Why do you ask?", "Does that question interest you?", "What is it you really want to know?", "What do you think?", "what comes to your mind when you ask that?"]
    },
    {
      pattern: "?X perhaps ?Y",
      responses: ["You do not seem quite certain"]
    },
    {
      pattern: "?X are ?Y",
      responses: ["Do you think they might not be ?Y?", "Posssibly they are ?Y"]
    },
    {
      pattern: "?X",
      responses: ["Very interesting", "I am not sure I understand you fully", "What does that suggest to you?", "Please continue", "Go on", "Do you feel strongly about discussing such things?"]
    },
  ]
end
