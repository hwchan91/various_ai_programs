require 'pry'

class Op
  attr_accessor :action, :preconds, :add_list, :del_list

  def initialize(opt = {})
    @action   = opt[:action]
    @preconds = opt[:preconds] || []
    @add_list = opt[:add_list] || []
    @del_list = opt[:del_list] || []
  end
end

class Gps
  attr_accessor :all_ops, :level, :current_state

  def initialize(opt = {})
    @current_state = opt[:state]
    @goals         = opt[:goals]
    @all_ops       = opt[:all_ops]
    @steps         = []
    @steps_history  = {}
  end

  def solve
    achieve_all ? @steps : 'Not possible'
  rescue => e
    binding.pry
  end

  def achieve_all
    return true if all_goals_achieved?(@goals)

    executable_ops.find do |op|
      temp = get_snapshot
      apply(op)
      return true if all_goals_achieved?(@goals)
      return true if achieve_all

      backtrack(temp) && false
    end
  end

  def already_achieved?(goal)
    @current_state.include?(goal)
  end

  def get_achieved_goals(goals, achieved_goals)
    ((goals - @current_state) + achieved_goals).uniq
  end

  def get_snapshot
    [@current_state.dup, @steps.dup, deep_copy(@steps_history)]
  end

  def backtrack(temp)
    @current_state = temp[0]
    @steps         = temp[1]
    @steps_history = temp[2]
  end

  def executable_ops
    curr_precons_achieved_avg = get_precons_achieved_avg
    ops = immediately_executable_ops

    ops_with_ranking = ops.map do |op|
      new_state_after_execution = (@current_state + op.add_list - op.del_list).uniq
      {
        op: op,
        precons_achieved_avg: get_precons_achieved_avg(new_state_after_execution),
        goals_achieved_count: (@goals - (@goals - new_state_after_execution)).size,
        state_changed: state_changed?(new_state_after_execution)
      }
    end

    ops_with_ranking.select!{ |h| h[:state_changed] }
    ops_with_ranking.sort_by!{ |h| [h[:goals_achieved_count], h[:precons_achieved_avg]] }.reverse! # precons_avg takes precedence before goals count (due to reverse)
    ops_with_ranking.reject!{ |h| h[:precons_achieved_avg] < curr_precons_achieved_avg }
    return [] if ops_with_ranking.empty?
    ops_with_ranking.map!{ |h| h[:op] }.reject!{ |op| infinite_loop?(op) }

    ops_with_ranking
  end

  def immediately_executable_ops
    all_ops.select{ |op| (op.preconds - @current_state).empty? }
  end

  def get_precons_achieved_avg(state = @current_state)
    precons_arr = precons_percentage_achieved_per_goal(state)
    return 1 if precons_arr.empty?
    average(precons_arr)
  end

  def average(arr)
    arr.reduce(:+) / arr.size.to_f
  end

  def precons_percentage_achieved_per_goal(state)
    common_precons_of_remaining_goals(state).map do |common_precons|
      if common_precons.empty?
        1
      else
        common_precons_achieved = common_precons - (common_precons - state)
        common_precons_achieved.size / common_precons.size.to_f
      end
    end
  end

  def common_precons_of_remaining_goals(state)
    remaining_goals = @goals - state
    remaining_goals_indexes = remaining_goals.map{ |goal| @goals.index(goal) }
    remaining_goals_indexes.map{ |i| common_precons_of_ultimate_goals[i] }
  end

  def common_precons_of_ultimate_goals #never changes
    @common_precons_of_ultimate_goals ||= @goals.map do |goal|
      ops_one_move_away = all_ops.select{ |op| op.add_list.include?(goal) }
      common_precons = ops_one_move_away.map{ |op| op.preconds }.inject(:&)
    end.map{ |arr| arr.nil? ? [] : arr }
  end

  def destroy_achieved_goals?(op, achieved_goals)
    achieved_goals.size > (achieved_goals - op.del_list).size
  end

  def apply(op)
    return unless op.is_a? Op
    @current_state = (@current_state - op.del_list + op.add_list).uniq
    @steps << "Execute #{op.action}"
    update_steps_history(op)
  end

  def update_steps_history(op)
    if @steps_history[current_state_as_key]
      @steps_history[current_state_as_key] << op.action
    else
      @steps_history[current_state_as_key] = [op.action]
    end
  end

  def current_state_as_key
    @current_state.sort.join(", ")
  end

  def infinite_loop?(op)
    return unless steps_taken = @steps_history[current_state_as_key]
    steps_taken.find{ |step| step == op.action }
  end

  def state_changed?(state)
    state.sort != @current_state.sort
  end

  def all_goals_achieved?(goals)
    (goals - @current_state).empty?
  end

  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end
end



school_ops = [
  Op.new({
    action: 'drive son to school',
    preconds: ['son at home', 'car works'],
    add_list: ['son at school'],
    del_list: ['son at home']
  }),
  Op.new({
    action: 'shop installs battery',
    preconds: ['car needs battery', 'shop knows problem', 'shop has money'],
    add_list: ['car works']
  }),
  Op.new({
    action: 'tell shop problem',
    preconds: ['in communication with shop'],
    add_list: ['shop knows problem']
  }),
  Op.new({
    action: 'telephone shop',
    preconds: ['know phone number'],
    add_list: ['in communication with shop']
  }),
  Op.new({
    action: 'look up number',
    preconds: ['have phone book'],
    add_list: ['know phone number']
  }),
  Op.new({
    action: 'give shop money',
    preconds: ['have money', 'shop knows problem'],
    add_list: ['shop has money'],
    del_list: ['have money']
  })
]

Gps.new(state: ['son at home', 'car needs battery', 'have money', 'have phone book'], goals:['son at school'], all_ops: school_ops).solve

school_ops = [Op.new({
  action: 'taxi son to school',
  preconds: ['son at home', 'have money'],
  add_list: ['son at school'],
  del_list: ['son at home', 'have money']
})] + school_ops
# returns not possible for v1 of GPS because of 'not looking after you don't leap'
Gps.new(state: ['son at home', 'car works', 'have money'], goals:['son at school', 'have money'], all_ops: school_ops).solve

banana_ops = [
  Op.new(
    action: 'climb on chair',
    preconds: ['chair at middle room', 'at middle room', 'on floor'],
    add_list: ['at bananas', 'on chair'],
    del_list: ['at middle room', 'on floor']
  ),
  Op.new(
    action: 'push chair from door to middle room',
    preconds: ['chair at door', 'at door'],
    add_list: ['chair at middle room', 'at middle room'],
    del_list: ['chair at door', 'at door']
  ),
  Op.new(
    action: 'walk from door to middle room',
    preconds: ['on floor', 'at door'],
    add_list: ['at middle room'],
    del_list: ['at door']
  ),
  Op.new(
    action: 'grasp bananas',
    preconds: ['at bananas', 'empty-handed'],
    add_list: ['has bananas'],
    del_list: ['empty-handed']
  ),
  Op.new(
    action: 'drop ball',
    preconds: ['has ball'],
    add_list: ['empty-handed'],
    del_list: ['has ball']
  ),
  Op.new(
    action: 'eat bananas',
    preconds: ['has bananas'],
    add_list: ['empty-handed', 'not hungry'],
    del_list: ['has bananas', 'hungry']
  )
]

Gps.new(state: ['at door', 'on floor', 'has ball', 'hungry', 'chair at door'], goals:['not hungry'], all_ops: banana_ops).solve

def make_maze_ops(path_arr)
  [make_maze_op(path_arr[0], path_arr[1]), make_maze_op(path_arr[1], path_arr[0])]
end

def make_maze_op(here, there)
  Op.new({
    action: "move from #{here} to #{there}",
    preconds: ["at #{here}"],
    add_list: ["at #{there}"],
    del_list: ["at #{here}"]
  })
end

maze_ops = [
  [1, 2],
  [2, 3],
  [3, 4],
  [4, 9],
  [9, 14],
  [9, 8],
  [8, 7],
  [7, 12],
  [12, 13],
  [12, 11],
  [11, 6],
  [11, 16],
  [16, 17],
  [17, 22],
  [21, 22],
  [22, 23],
  [23, 18],
  [23, 24],
  [24, 19],
  [19, 20],
  [20, 15],
  [15, 10],
  [10, 5],
  [20, 25]
].map{ |path_arr| make_maze_ops(path_arr) }.flatten

Gps.new(state: ['at 1'], goals:['at 25'], all_ops: maze_ops).solve


def make_block_ops(blocks)
  ops = []

  blocks.permutation(3).to_a.each do |a, b, c|
    ops << make_block_op(a, b, c)
  end

  blocks.permutation(2).to_a.each do |a, b|
    ops << make_block_op(a, 'table', b)
    ops << make_block_op(a, b, 'table')
  end

  ops
end

# there is always space on table
def make_block_op(block, prev_loc, new_loc)
  Op.new({
    action: "move #{block} from #{prev_loc} to #{new_loc}",
    preconds: ["space on #{block}", "space on #{new_loc}", "#{block} on #{prev_loc}"] - ['space on table'],
    add_list: move_on(block, prev_loc, new_loc),
    del_list: move_on(block, new_loc, prev_loc)
  })
end

def move_on(block, prev_loc, new_loc)
  ["#{block} on #{new_loc}", "space on #{prev_loc}"] - ['space on table']
end

Gps.new(state: ['a on table', 'b on table', 'space on a', 'space on b'], goals:['a on b', 'b on table'], all_ops: make_block_ops(['a', 'b'])).solve

Gps.new(state: ['a on b', 'b on table', 'space on a'], goals:['b on a'], all_ops: make_block_ops(['a', 'b'])).solve

Gps.new(state: ['c on a', 'b on table', 'space on c', 'space on b'], goals:['c on table'], all_ops: make_block_ops(['a', 'b', 'c'])).solve

Gps.new(state: ['c on a', 'a on table', 'b on table', 'space on c', 'space on b'], goals:['c on table', 'a on b'], all_ops: make_block_ops(['a', 'b', 'c'])).solve

Gps.new(state: ['a on b', 'b on c', 'c on table', 'space on a'], goals:['c on b', 'b on a',], all_ops: make_block_ops(['a', 'b', 'c'])).solve

# sussman anomaly happens because: after solving b on c (immediately), to solve a on b, 'b on c' will have be destroyed; at the point when a on b is achieved, b is no longer on c; same for reverse condition
# the following does not work: one a is above b, and cannot be broken, the goal is not achievable
Gps.new(state: ['c on a', 'b on table', 'a on table', 'space on b', 'space on c'], goals:['a on b','b on c'], all_ops: make_block_ops(['a', 'b', 'c'])).solve
# the following works (although not optimally)
Gps.new(state: ['c on a', 'b on table', 'a on table', 'space on b', 'space on c'], goals:['b on c','a on b'], all_ops: make_block_ops(['a', 'b', 'c'])).solve
# solution: automatically mix up goal seq => works for both now
