require 'pry'

class TicTacToe
  attr_accessor :board, :curr_sym
  POS_BOARD = [[[0, 0], [0, 1], [0, 2]], [[1, 0], [1, 1], [1, 2]], [[2, 0], [2, 1], [2, 2]]]
  TOP_LEFT_DIAGONAL = [[0,0], [1,1], [2,2]]
  TOP_RIGHT_DIAGONAL = [[0,2], [1,1], [2,0]]

  def initialize
    @board   = (1..3).map{ Array.new(3) }
  end

  # return winning symbol or nil
  def self.won?(board)
    winning_line = all_lines(board).detect do |line|
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

  def self.evaluate_board(board, curr_sym, limit_depth = 9)
    move_count = filled_boxes_count(board)

    case
    when won?(board)
      get_values_given_move_count(move_count, curr_sym)
    when move_count.between?(3, 4) && win_after_four_moves?(board, curr_sym)
      get_values_given_move_count(move_count + 4, curr_sym)
    when limit_depth <= 0
      [0, 0]  #assuming tie if cannot guarantee win after limit_depth
    else
      nil
    end
  end

  def self.win_after_four_moves?(board, curr_sym)
    curr_sym_pos = get_sym_pos(board, curr_sym)
    opponent_sym_pos = get_sym_pos(board, get_opposite_sym(curr_sym))

    curr_calling_on = calling_on(curr_sym_pos, opponent_sym_pos)
    return false if !curr_calling_on || calling_on(opponent_sym_pos, curr_sym_pos)

    !pos_on_opponent_occupied_lines(curr_calling_on, opponent_sym_pos)
  end

  def self.pos_on_opponent_occupied_lines(pos, opponent_sym_pos)
    occupied_rows(opponent_sym_pos).include?(pos.first) ||
    occupied_columns(opponent_sym_pos).include?(pos.last) ||
    occupied_diagonals(opponent_sym_pos).include?(occupied_diagonals([pos]).first)
  end

  def self.calling_on(curr_sym_pos, opponent_sym_pos)
    return if curr_sym_pos.size < 2
    all_lines(POS_BOARD).each do |line|
      remaining_tiles = line - curr_sym_pos
      return remaining_tiles.first if remaining_tiles.size == 1 && !opponent_sym_pos.include?(remaining_tiles.first)
    end
    nil
  end

  def self.get_sym_pos(board, sym)
    board = board.flatten
    POS_BOARD.flatten(1).map.with_index{ |pos, i| board[i] == sym ? pos : nil }.compact
  end

  def self.occupied_rows(sym_pos)
    sym_pos.map(&:first).uniq
  end

  def self.occupied_columns(sym_pos)
    sym_pos.map(&:last).uniq
  end

  # the 2 diagonals are given number 0 & 1
  def self.occupied_diagonals(sym_pos)
    arr = []
    arr << 0 if (TOP_LEFT_DIAGONAL - sym_pos).size < 3
    arr << 1 if (TOP_RIGHT_DIAGONAL - sym_pos).size < 3
    arr
  end

  def self.get_values_given_move_count(move_count, winning_sym)
    score = 10 - move_count
    scores = [score, -score]
    scores.reverse! if symbol_map.key(winning_sym) == 1
    scores
  end

  def self.filled_boxes_count(board)
    board.flatten.count { |box| box }
  end

  def self.all_filled?(board)
    filled_boxes_count(board) == 9
  end

  def self.all_lines(board)
    rows(board) + columns(board) + diagonals(board)
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

  def self.get_opposite_sym(sym)
    sym == 'X' ? 'O' : 'X'
  end

  def self.get_best_move(board, curr_player_pos)
    move, _, _ = best_move_in_table(board, curr_player_pos)
    move
  end

  def self.best_move_in_table(board, player_pos, alpha: -infinity, beta: infinity, limit_depth: 3)
    cached_result = cache[get_key(board, player_pos)]
    return cached_result if cached_result

    score_table = get_score_table(board, player_pos, alpha, beta, limit_depth)
    scores = score_table.values.map{ |v| v[player_pos] }
    pos_in_table_for_max_score = scores.index(scores.max)
    best_move_and_values = [score_table.keys[pos_in_table_for_max_score], score_table.values[pos_in_table_for_max_score]]
    add_to_cache(board, player_pos, best_move_and_values)
    best_move_and_values
  end

  def self.get_score_table(board, curr_player_pos, alpha, beta, limit_depth)
    score_table       = {}
    next_player_pos   = get_next_player_pos(curr_player_pos)
    first_player_best = -infinity
    curr_sym          = symbol_map[curr_player_pos]
    limit_depth      -= 1

    successor_states(board, curr_sym).each do |move, new_board|
      end_scores = evaluate_board(new_board, curr_sym, limit_depth)
      unless end_scores
        _, end_scores = best_move_in_table(new_board, next_player_pos, alpha: alpha, beta: beta, limit_depth: limit_depth)
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

  def self.cache
    @@cache ||= {}
  end

  def self.get_key(board, player_pos)
    board.flatten.map{|sym| sym.nil? ? "." : sym}.join + player_pos.to_s # e.g.  X..O..XXO1
  end

  def self.add_to_cache(board, player_pos, best_move_and_values)
    best_move, values = best_move_and_values
    rotated_boards = get_rotated_boards(board, best_move)
    mirrored_boards = get_mirrored_boards_in_bulk(rotated_boards)

    (rotated_boards + mirrored_boards).each do |board, move|
      @@cache[get_key(board, player_pos)] = [move, values]
    end
  end

  def self.get_rotated_boards(board, move)
    rotated_boards = [[board, move]]
    3.times do
      board = rotated_board(board)
      move  = rotated_move(move)
      rotated_boards << [board, move]
    end
    rotated_boards
  end

  def self.rotated_board(board)
    columns(board).map(&:reverse)
  end

  def self.rotated_move(move)
    [move[1], 2 - move[0]]
  end

  def self.get_mirrored_boards_in_bulk(boards)
    boards.map do |board, move|
      [mirrored_board(board), mirrored_move(move)]
    end
  end

  def self.mirrored_board(board)
    board.map(&:reverse)
  end

  def self.mirrored_move(move)
    [move[0], 2 - move[1]]
  end
end

# board = [
#   [nil, nil, nil],
#   [nil, nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.get_best_move(board, 0) # => [0,0]/[1,1] since there is no guarantee win, and it's not calculating the percentage of wins, it wouldn't suggest taking the corner even if it's more likely to win

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


# board = [
#   ['O', 'X', 'X'],
#   [nil, nil, nil],
#   ['O', nil, nil]
# ]
# TicTacToe.win_after_four_moves?(board, 'O')



# board = [
#   ['O', 'X', 'X'],
#   ['O', nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.win_after_four_moves?(board, 'O')

# board = [
#   ['X', 'X', nil],
#   ['O', nil, nil],
#   [nil, nil, nil]
# ]
# TicTacToe.win_after_four_moves?(board, 'X')
