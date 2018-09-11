require 'ostruct'
require 'pry'

class Tile
  attr_accessor :row, :column, :coord

  def initialize(arr)
    @row    = arr[0]
    @column = arr[1]
    @coord  = arr.clone
  end
end

class EightQueens
  BASE_ANNEALING_TEMP = 1
  PREFERRED_STRATEGY = 'annealing_move' #'first_choice_move' #'stochastic_move' #'greedy_move' #'first_choice_move'

  def self.tiles_attacked_by_pos(origin)
    coords = []
    8.times { |i| coords += [[origin.row, i], [i, origin.column]] }
    (-7..7).each{ |k| coords += [[origin.row + k, origin.column + k], [origin.row + k, origin.column - k]] }
    coords.select! { |coord| coord[0].between?(0, 7) && coord[1].between?(0, 7) }
    coords.uniq - [origin.coord]
  end

  def self.queens_attacked_count_by_pos(origin, queens)
    8 - (queens.map(&:coord) - tiles_attacked_by_pos(origin)).size
  end

  def self.queens_attacked_count(queens)
    queens.inject(0) { |count, queen| count + queens_attacked_count_by_pos(queen, queens) } / 2
  end

  def self.successor_states(queens)
    successors = []
    queens.each do |queen|
      other_queens = queens - [queen]
      (0..7).each do |i|
        next if queen.column == i
        new_queens = other_queens + [Tile.new([queen.row, i])]
        successors.push([new_queens, queens_attacked_count(new_queens)])
      end
    end

    successors
  end

  def self.greedy_move(queens)
    current_count = queens_attacked_count(queens)
    successors = successor_states(queens)
    best_score = successors.map(&:last).min
    return if best_score >= current_count
    successors.find{ |successor| successor.last == best_score }
  end

  def self.first_choice_move(queens)
    current_count = queens_attacked_count(queens)

    queens.each do |queen|
      other_queens = queens - [queen]
      (0..7).each do |i|
        next if queen.column == i
        new_queens = other_queens + [Tile.new([queen.row, i])]
        new_count = queens_attacked_count(new_queens)
        return [new_queens, new_count] if new_count < current_count
      end
    end
    nil
  end

  def self.stochastic_move(queens)
    current_score = queens_attacked_count(queens)
    successor_states(queens).select{ |successor| successor.last < current_score }.sample
  end

  def self.solve(queens)
    new_queens, new_score = send(PREFERRED_STRATEGY, queens)
    return if new_queens.nil?
    return new_queens if new_score == 0
    solve(new_queens)
  end

  def self.print_board(queens)
    puts "---------------------------------"
    queens.sort_by{ |q| q.row }.each do |queen|
      puts ("|" + (0..7).map{ |col| col == queen.column ? ' Q |' : '   |' }.join)
      puts "---------------------------------"
    end
  end

  def self.rand_queens
    (0..7).map{|i| Tile.new([i, rand(8)])}
  end

  def self.get_sol(tries = 1)
    reset_annealing_temp
    sol = solve(rand_queens)
    if sol
      puts("total tries: #{tries}")
      return sol
    end

    get_sol(tries += 1)
  end

  def self.annealing_move(queens)
    current_score = queens_attacked_count(queens)
    new_queens = random_move(queens)
    new_score = queens_attacked_count(new_queens)
    if new_score < current_score || rand((28 - current_score)/@temp) == 0 # as state approaches sol, less likely to accept move
      @temp = @temp * 0.95 unless @temp < 0.3
      return [new_queens, new_score]
    end
    annealing_move(queens) # else get another random move
  end

  def self.reset_annealing_temp
    @temp = BASE_ANNEALING_TEMP
  end

  def self.random_move(queens)
    moved_queen  = queens.sample
    new_queen = Tile.new([moved_queen.row, get_rand_column_except(moved_queen.column)])
    queens - [moved_queen] + [new_queen]
  end

  def self.get_rand_column_except(i)
    col = rand(8)
    col == i ? get_rand_column_except(i) : col
  end
end

# queens = [ [0,2], [1,3], [2,1], [3,7], [4,6], [5,5], [6,2], [7,1] ].map{|pos| Tile.new(pos) }
# sol = EightQueens.solve(queens)
# EightQueens.print_board(sol)
time = Time.now
EightQueens.print_board EightQueens.get_sol
p Time.now - time
