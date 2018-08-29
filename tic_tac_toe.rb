require 'pry'

class TicTacToe
  attr_accessor :board, :curr_sym

  def initialize
    @board   = (1..3).map{ Array.new(3) }
  end

  def self.get_next_symbol(sym)
    sym == 'X' ? 'O' : 'X'
  end

  # return winning symbol or nil
  def self.get_winning_sym(board)
    winning_line = (rows(board) + columns(board) + diagonals(board)).detect do |line|
      sym = line.first
      line.all? { |box| box && box == sym }
    end
    return unless winning_line
    winning_line.first
  end

  def self.first_player_sym
    'X'
  end

  # returns array [1st player score, 2nd player score], or nil
  def self.evaluate_board(board)
    winning_sym = get_winning_sym(board)

    case
    when winning_sym
      winning_sym == first_player_sym ? [1, -1] : [-1, 1]
    when all_filled?(board)
      [0, 0]
    else
      nil
    end
  end

  def self.all_filled?(board)
    board.flatten.all? { |box| box }
  end

  def self.rows(board)
    board
  end

  def self.columns(board)
    rows = rows(board)
    rows[0].zip(rows[1], rows[2])
  end

  def self.diagonals(board)
    rows = rows(board)
    [
      [ rows[0][0], rows[1][1], rows[2][2] ],
      [ rows[0][2], rows[1][1], rows[2][0] ]
    ]
  end

  def self.place_move(board, row:, col:, sym:)
    board[row][col] = sym
    board
  end

  def self.successor_states(board, sym)
    successors = {}
    3.times do |row|
      3.times do |col|
        next if board[row][col]
        successor = place_move(board_copy(board), row: row, col: col, sym: sym)
        successors[[row, col]] = successor
      end
    end
    successors
  end

  def self.board_copy(board)
    Marshal.load(Marshal.dump(board))
  end

  def self.get_next_player_pos(curr_player_pos)
    curr_player_pos == 0 ? 1 : 0
  end

  def self.get_score_table(board, sym, curr_player_pos)
    score_table = {}
    next_player_pos = get_next_player_pos(curr_player_pos)

    successor_states(board, sym).each do |move, new_board|
      end_score = evaluate_board(new_board)
      if end_score
        score_table[move] = end_score
        next
      end

      next_score_table = get_score_table(new_board, get_next_symbol(sym), next_player_pos)
      _, values = best_move_in_table(next_score_table, next_player_pos)
      score_table[move] = values
    end

    score_table
  end

  def self.best_move_in_table(score_table, player_pos)
    scores = score_table.values.map{ |v| v[player_pos] }
    pos_in_table_for_max_score = scores.index(scores.max)
    move, values = score_table.keys[pos_in_table_for_max_score], score_table.values[pos_in_table_for_max_score]
  end

  def self.get_best_move(board, sym, curr_player_pos)
    score_table = get_score_table(board, sym, curr_player_pos)
    move, _ = best_move_in_table(score_table, curr_player_pos)
    move
  end
end

# board = [
#   ['X', 'O', 'O'],
#   ['X', 'O', 'X'],
#   [nil, nil, nil]
# ]

board = [
  ['X', 'O', nil],
  [nil, nil, nil],
  [nil, nil, nil]
]
TicTacToe.get_best_move(board, "X", 0)

board = [
  ['X', 'O', nil],
  ['X', nil, nil],
  [nil, nil, nil]
]
TicTacToe.get_best_move(board, "O", 1)

board = [
  ['X', 'O', 'O'],
  ['X', nil, nil],
  [nil, nil, nil]
]
TicTacToe.get_best_move(board, "X", 0)

board = [
  ['X', 'O', 'O'],
  ['X', 'X', nil],
  [nil, nil, nil]
]
TicTacToe.get_best_move(board, "O", 1)

board = [
  ['X', 'O', 'O'],
  ['X', 'X', 'O'],
  [nil, nil, nil]
]
TicTacToe.get_best_move(board, "X", 0)

board = [
  ['X', 'O', 'O'],
  ['X', 'X', 'O'],
  ['X', nil, nil]
]
