class SentenceGenerator
  class << self
    attr_accessor :basic_grammar, :bigger_grammar, :grammar

    def generate(phrase)
      new_phrase = grammar[phrase.to_sym].sample
      return new_phrase if (new_phrase.is_a?(String) || new_phrase.nil?)
      new_phrase.map{|p| generate(p)}.flatten.compact.join(" ")
    end
  end

  @bigger_grammar = @basic_grammar.merge({
    noun_phrase:               [%w(article adjective_phrase noun prepositional_phrase), %w(name), %w(pronoun)],
    verb_phrase:               [%w(verb noun_phrase prepositional_phrase_plus)],
    prepositional_phrase_plus: [nil, %w(prepositional_phrase prepositional_phrase_plus)],
    prepositional_phrase:      [%w(preposition noun_phrase)],
    adjective_phrase:          [nil, %w(adjective adjective_phrase)],
    name:                      %w(Pat Kim Lee Terry Robin),
    pronoun:                   %w(he she it these those that),
    preposition:               %w(to in by with on),
    adjective:                 %w(big little blue green adabatic)
  })

  @basic_grammar = {
    sentence:                  [%w(noun_phrase verb_phrase)],
    noun_phrase:               [%w(article noun)],
    verb_phrase:               [%w(verb noun_phrase)],
    article:                   %w(the a),
    noun:                      %w(man ball woman table),
    verb:                      %w(hit took saw liked)
  }
  @grammar = @basic_grammar
end

SentenceGenerator.generate(:sentence)
SentenceGenerator.grammar = SentenceGenerator.bigger_grammar
SentenceGenerator.generate(:sentence)
