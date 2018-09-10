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
    count_both_sides = queens.inject(0) { |count, queen| count + queens_attacked_count_by_pos(queen, queens) }
    count_both_sides / 2
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

  def self.move(queens)
    current_count = queens_attacked_count(queens)
    successors = successor_states(queens)
    best_score = successors.map(&:last).min
    return if best_score >= current_count
    successors.find{ |successor| successor.last == best_score }
  end

  def self.solve(queens)
    new_queens, new_score = move(queens)
    return if new_queens.nil?
    return new_queens if new_score == 0
    solve(new_queens)
  end

  def self.print_board(queens)
    coords = queens.map(&:coord)
    board = []
    8.times do |i|
      row = []
      8.times do |j|
        tile = coords.include?([i, j]) ? ' Q ' : '   '
        row << tile
      end
      board << row
    end

    puts "---------------------------------"
    board.each do |row|
      puts ("|" + row.map{ |col| "#{col}|" }.join)
      puts "---------------------------------"
    end
  end
end

queens = [ [0,2], [1,3], [2,1], [3,7], [4,6], [5,5], [6,2], [7,1] ].map{|pos| Tile.new(pos) }
sol = EightQueens.solve(queens)
EightQueens.print_board(sol)
