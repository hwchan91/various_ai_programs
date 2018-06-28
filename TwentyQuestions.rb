require 'pry'

class Node
  attr_accessor :name, :yes, :no

  def initialize(opt = {})
    @name = opt[:name]
    @yes = opt[:yes]
    @no = opt[:no]
  end
end

class TwentyQuestion
  class << self
    attr_accessor :base

    def questions(node = base)
      p "Is it a #{node.name}?"

      case gets.chomp.downcase
      when "y", "yes"
        node.yes.nil? ? give_up(node, "yes") : questions(node.yes)
      when "n", "no"
        node.no.nil? ? give_up(node, "no") : questions(node.no)
      when "it"
        p "aha!"
      else
        p "Reply with YES/Y, NO/N, and IT if I guessed it"
      end
    end

    def give_up(node, response)
      p "\nI give up. What is it?"
      node.send("#{response}=", Node.new(name: gets.chomp.downcase))
    end
  end

  @base = Node.new({
    name: 'animal',
    yes: Node.new(name: 'mammal'),
    no: Node.new(name: 'vegetable', no: Node.new(name: 'mineral'))
  })
end

TwentyQuestion.questions
