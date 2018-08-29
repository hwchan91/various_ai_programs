require 'pry'

class TicTacToe
  attr_accessor :board, :curr_sym

  def initialize
    @board   = (1..3).map{ Array.new(3) }
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

  def self.symbol_map
    @@symbol_map ||= {
      0 => 'X',
      1 => 'O',
    }
  end

  # returns array [1st player score, 2nd player score], or nil
  def self.evaluate_board(board)
    depth = filled_boxes_count(board)
    winning_sym = get_winning_sym(board)

    case
    when winning_sym
      score = 10 - depth
      scores = [score, -score]
      scores.reverse! if symbol_map.key(winning_sym) == 1
      scores
    when all_filled?(board)
      [0, 0]
    else
      nil
    end
  end

  def self.filled_boxes_count(board)
    board.flatten.count { |box| box }
  end

  def self.all_filled?(board)
    filled_boxes_count(board) == 9
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
    curr_player_pos == symbol_map.size - 1 ? 0 : curr_player_pos + 1
  end

  def self.get_best_move(board, curr_player_pos)
    move, _, _ = best_move_in_table(board, curr_player_pos)
    move
  end

  def self.best_move_in_table(board, player_pos, alpha: -infinity, beta: infinity)
    score_table = get_score_table(board, player_pos, alpha, beta)
    scores = score_table.values.map{ |v| v[player_pos] }
    pos_in_table_for_max_score = scores.index(scores.max)
    move, values = score_table.keys[pos_in_table_for_max_score], score_table.values[pos_in_table_for_max_score]
  end

  def self.get_score_table(board, curr_player_pos, alpha, beta)
    score_table = {}
    next_player_pos = get_next_player_pos(curr_player_pos)
    first_player_best = -infinity

    successor_states(board, symbol_map[curr_player_pos]).each do |move, new_board|
      end_scores = evaluate_board(new_board)
      unless end_scores
        _, end_scores = best_move_in_table(new_board, next_player_pos, alpha: alpha, beta: beta)
      end

      first_player_best = [first_player_best, end_scores[0]].max
      score_table[move] = end_scores

      if curr_player_pos == 0
        alpha = [alpha, first_player_best].max
        break if first_player_best >= beta  # from the standpoint of the 2nd player, the best 2nd player can get (or the worst the 1st player can get) is worse than that of another successor state, thus no need to pursue
      else
        beta = [beta, first_player_best].min
        break if first_player_best <= alpha # from the standpoint of the 1st player, the best 1st player can get is worse than that of another successors state, thus no need to pursue
      end
    end

    score_table
  end

  def self.infinity
    1.0/0
  end
end


# board = [
#   [nil, nil, nil],
#   [nil, nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.get_best_move(board, 0) # => [0,0]

# board = [
#   ['X', nil, nil],
#   [nil, nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.get_best_move(board, 1) # => [1,1]

# board = [
#   ['X', 'O', nil],
#   [nil, nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.get_best_move(board, 0)

# board = [
#   ['X', 'O', nil],
#   ['X', nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.get_best_move(board, 1)

# board = [
#   ['X', 'O', nil],
#   ['X', nil, nil],
#   ['O', nil, nil]
# ]
# TicTacToe.get_best_move(board, 0)

# board = [
#   ['X', 'O', nil],
#   ['X', 'X', nil],
#   ['O', nil, nil]
# ]
# TicTacToe.get_best_move(board, 1) # => returns [0,2] which does not block any X lines, because even if O blocks it, X is still going to win in the next move, thefore all moves evaluate to the same score
