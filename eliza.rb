require './rule_based_translator.rb'

class Eliza < RuleBasedTranslator
  class << self
    attr_accessor :eliza_rules

    def run
      action_func = Proc.new do |response, variable_map|
        response = response.sample.dup
        variable_map.each { |variable, value| response.gsub!(variable, switch_viewpoint(value)) }
        puts response
      end

      puts "hello"
      loop { translate(input: transform(gets.chomp), rules: expand_rules(eliza_rules), action_func: action_func) }
    end

    def transform(input)
      input.downcase.gsub(",", "").gsub(".", "").gsub("i am", "I'm").gsub("cannot", "can't").gsub("do not", "don't")
    end

    def switch_viewpoint(words)
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
          when 'yourself' then 'myself'
          when 'myself' then 'yourself'
          else word
          end
        end
        words.join(" ").gsub("I are", "I am")
    end
  end

  @eliza_rules = expand_pattern([
    {
      pattern: [%w(?X* fuck ?Y*), %w(?X* shit ?Y*), %w(?X* cunt ?Y*)],
      responses: ["You seem angry", "Words cannot hurt me","What have I done to make you use such language?", "Same to you", "What made you behave so childishly?"]
    },
    {
      pattern: [%w(?X* hello ?Y*), %w(?X* hi ?Y*)],
      responses: ["How do you do. Please state your problem."]
    },
    {
      pattern: [%w(?X* computer ?Y*)],
      responses: ["Do computer worry you?", "What do you think about machines?", "Why do you mention computers?", "What do you think machines have to do with your problem?"]
    },
    {
      pattern: [%w(?X* name ?Y*)],
      responses: ["I'm not interested in names"]
    },
    {
      pattern: [%w(?X* sorry ?Y*)],
      responses: ["Please don't apologize", "Apologies are not necessary", "What feelings do you have when you apologize?"]
    },
    {
      pattern: [%w(?X* I remember ?Y*)],
      responses: ["Do you often think of %Y?", "Does thinking of ?Y bring anything else to mind?", "What else do you remember?", "Why do you recall ?Y right now?", "What in the present situation reminds you of ?Y?", "What is the connection between me and ?Y?"]
    },
    {
      pattern: [%w(?X* do you remember ?Y*)],
      responses: ["Do you think I would forget ?Y?", "Why do you think I should recall ?Y now?", "what about ?Y?", "You mention ?Y?"]
    },
    {
      pattern: [%w(?X* if ?Y*)],
      responses: ["Do you really think its likely that ?Y?", "Do you wish that ?Y?", "What do you think about ?Y?", "Really? if ?Y"]
    },
    {
      pattern: [%w(?X* I dreamt ?Y*)],
      responses: ["Really? ?Y?", "Have you ever fantacized ?Y while you were awake?", "Have you dreamt ?Y before?"]
    },
    {
      pattern: [%w(?X* my mother ?Y*)],
      responses: ["Who else in your family ?Y?", "Tell me more about your family"]
    },
    {
      pattern: [%w(?X* my father ?Y*)],
      responses: ["Your father?", "Does he influence you strongly?", "What else comes to mind when you think of your father?"]
    },
    {
      pattern: [%w(?X* dream about ?Y*)],
      responses: ["How do you feel about ?Y in reality?", "?X dream ?Y?", "What does this dream suggest to you?", "Do you dream often?", "What persons appear in your dream?", "Don't you believe that dream has to do with your problem?"]
    },
    {
      pattern: [%w(?X* I want ?Y*)],
      responses: ["What would it mean if you got ?Y?", "Why do you want ?Y?", "Suppose you got ?Y soon"]
    },
    {
      pattern: [%w(?X* I'm glad ?Y*)],
      responses: ["What have I helped you to be ?Y?", "What makes you happy just now?", "Can you explain why you are suddenly happy ?Y"]
    },
    {
      pattern: [%w(?X* I'm sad ?Y*)],
      responses: ["I am sorry to here you are depressed", "I'm sure it's not pleasant to be sad"]
    },
    {
      pattern: [%w(?X* are like ?Y*)],
      responses: ["What resemblance do you see between ?X and ?Y?"]
    },
    {
      pattern: [%w(?X* is like ?Y*)],
      responses: ["In what way is it that ?X is like ?Y?"]
    },
    {
      pattern: [%w(?X* alike ?Y*)],
      responses: ["In what way?", "What similarities are there?"]
    },
    {
      pattern: [%w(?X* same ?Y*)],
      responses: ["What other connections do you see?"]
    },
    {
      pattern: [%w(?X* I was ?Y*)],
      responses: ["Were you really?", "Perhaps I already knew you were ?Y", "Why do you tell me you were ?Y now?"]
    },
    {
      pattern: [%w(?X* was I ?Y*)],
      responses: ["What if you were ?Y?", "Do you think you were ?Y?", "What would it mean if you were ?Y?"]
    },
    {
      pattern: [%w(?X* I'm ?Y*)],
      responses: ["In what way are you ?Y?", "Do you want to be ?Y?"]
    },
    {
      pattern: [%w(?X* am I ?Y*)],
      responses: ["Do you believe you are ?Y?", "Would you want to be ?Y?", "You wish I would teel you you are ?Y?", "What would it mean if you were ?Y?"]
    },
    {
      pattern: [%w(?X* am ?Y*)],
      responses: ["Why do say AM?", "I don't understand that"]
    },
    {
      pattern: [%w(?X* are you ?Y*)],
      responses: ["Why are you interested in whether I am ?Y or not?", "Would you prefer if I weren't ?Y?", "Perhaps I am ?Y in your fantasies"]
    },
    {
      pattern: [%w(?X* you are ?Y*)],
      responses: ["What made you think I am ?Y?"]
    },
    {
      pattern: [%w(?X* because ?Y*)],
      responses: ["Is that the real reason?", "What other reason might there be?", "Does that reason seem to explain anything else?"]
    },
    {
      pattern: [%w(?X* were you ?Y*)],
      responses: ["Perhaps I was ?Y", "What do you think?", "What if I had been ?Y?"]
    },
    {
      pattern: [%w(?X* I can't ?Y*)],
      responses: ["Maybe you could ?Y now", "What if you could ?Y?"]
    },
    {
      pattern: [%w(?X* I feel ?Y*)],
      responses: ["Do you often feel ?Y?"]
    },
    {
      pattern: [%w(?X* I felt ?Y*)],
      responses: ["What other feelings do you have?"]
    },
    {
      pattern: [%w(?X* I ?Y* you ?Z*)],
      responses: ["Perhaps in your fantasy we ?Y each other"]
    },
    {
      pattern: [%w(?X* why don't you ?Y*)],
      responses: ["Should you ?Y?", "Do you believe I don't ?Y?", "Perhaps I will ?Y in good time"]
    },
    {
      pattern: [%w(?X* yes ?Y*)],
      responses: ["You seem quite positive", "You seem sure", "I understand"]
    },
    {
      pattern: [%w(?X* no ?Y*)],
      responses: ["Why not?", "You are being a bit negative", "Are you saying NO just to be negative?"]
    },
    {
      pattern: [%w(?X* someone ?Y*)],
      responses: ["Can you be more specific?"]
    },
    {
      pattern: [%w(?X* everyone ?Y*)],
      responses: ["Surely not everyone?", "Can you think of anyone in particular?", "Who for example?", "You are thinking of a special person"]
    },
    {
      pattern: [%w(?X* always ?Y*)],
      responses: ["Can you think of a specific example?", "When?", "What incident are you thinking of?", "Really? Always?"]
    },
    {
      pattern: [%w(?X* what ?Y*)],
      responses: ["Why do you ask?", "Does that question interest you?", "What is it you really want to know?", "What do you think?", "what comes to your mind when you ask that?"]
    },
    {
      pattern: [%w(?X* perhaps ?Y*)],
      responses: ["You do not seem quite certain"]
    },
    {
      pattern: [%w(?X* are ?Y*)],
      responses: ["Do you think they might not be ?Y?", "Posssibly they are ?Y"]
    },
    {
      pattern: [['?X*']],
      responses: ["?X - That seems interesting", "?X - I am not sure I understand you fully", "?X - What does that suggest to you?", "So ?X", "?X  - Do you feel strongly about discussing such things?"]
    },
  ])
end

Eliza.run
