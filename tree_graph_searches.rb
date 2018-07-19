require 'pry'

class Path
  attr_accessor :state, :previous, :cost_so_far, :total_cost

  def initialize(opt)
    @state       = opt[:state]
    @previous    = opt[:previous]
    @cost_so_far = opt[:cost_so_far] || 0
    @total_cost  = opt[:total_cost]  || 0
  end
end


def a_star_search(paths:,
                  goal_func:,
                  successor_func:,
                  cost_func:,
                  cost_left_func:,
                  eq_func: Proc.new { |x, y| x == y },
                  old_paths: [])

  return if paths.nil?
  return print_solution(paths.first) if goal_func.call(paths.first.state)

  path = paths.shift
  state = path.state
  old_paths = insert_path(path: path, paths: old_paths)

  successor_func.call(state).each do |successor_state|
    cost_so_far = path.cost_so_far + cost_func.call(state, successor_state)
    total_cost = cost_so_far + cost_left_func.call(successor_state)
    new_path = Path.new(state: successor_state, previous: path, cost_so_far: cost_so_far, total_cost: total_cost)

    same_in_curr = find_path(state: successor_state, paths: paths, eq_func: eq_func)
    same_in_old = find_path(state: successor_state, paths: old_paths, eq_func: eq_func)

    if same_in_curr
      if better_path?(new_path: new_path, old_path: same_in_curr)
        paths.delete(path_with_same_state_in_curr_paths)
        paths = insert_path(path: new_path, paths: paths)
      end
    elsif same_in_old
      if better_path?(new_path: new_path, old_path: same_in_old)
        old_paths.delete(path_with_same_state_in_old_paths)
        paths = insert_path(path: new_path, paths: paths)
      end
    else
      paths = insert_path(path: new_path, paths: paths)
    end
  end

  a_star_search(paths: paths,
                goal_func: goal_func,
                successor_func: successor_func,
                cost_func: cost_func,
                cost_left_func: cost_left_func,
                eq_func: eq_func,
                old_paths: old_paths)
end

def print_solution(path, solution = [])
  solution << path.state
  return solution.join(", ") if path.previous.nil?
  print_solution(path.previous, solution)
end

def insert_path(path:, paths:)
  paths.push(path).sort_by { |p| p.total_cost }
end

def find_path(state:, paths:, eq_func:)
  paths.detect { |p| eq_func.call(state, p.state) }
end

def better_path?(new_path:, old_path:)
  new_path.total_cost < old_path.total_cost
end

def is?(state)
  return Proc.new{ |dest| state == dest }
end

###############################################################
next_two = Proc.new{|i| [i+1, i+2] }
cost_one = Proc.new{|x,y| 1 }
diff_6 = Proc.new{ |i| (6 - i).abs }

a_star_search(paths: [Path.new(state: 1)],
              goal_func: is?(6),
              successor_func: next_two,
              cost_func: cost_one,
              cost_left_func: diff_6)
#################################################################





def tree_search(states:, goal_func:, successor_func:, combiner_func:)
  return unless states
  return states.first if goal_func.call(states.first)

  p states

  successor_states = successor_func.call(states.first)
  states = combiner_func.call(successor_states, states[1..-1] )
  tree_search(states: states, goal_func: goal_func, successor_func: successor_func, combiner_func: combiner_func)
end

def beam_search(start:, goal_func:, successor_func:, cost_func:, beam_width:)
  combiner_func = Proc.new do |arr1, arr2|
    states = (arr1 + arr2).sort_by{ |i| cost_func.call(i) }
    states.count > beam_width ? states[0...beam_width] : states
  end

  tree_search(states: [start],
              goal_func: goal_func,
              successor_func: successor_func,
              combiner_func: combiner_func)
end

def price_is_right(price)
  return Proc.new { |i| i > price ? 9999999999999 : price - i }
end

##########################################################
combine_arr = Proc.new{ |arr1, arr2| arr1 + arr2 }
tree_search(states: [1],
            goal_func: is?(6),
            successor_func: next_two,
            combiner_func: combine_arr)

binary_tree = Proc.new { |i| [i*2, i*2 + 1] }

beam_search(start: 1,
            goal_func: is?(12),
            successor_func: binary_tree,
            cost_func: price_is_right(12),
            beam_width: 2)
###########################################################




def gps_search(start:, goals:, ops:, beam_width: 10)
  sol = beam_search(start: start,
              goal_func: Proc.new { |state| (goals - state).empty? },
              successor_func: gps_successor(ops),
              cost_func: Proc.new do |state|
                action_count = state.select { |desc| is_action?(desc) }.count
                goals_not_achieved_count = (goals - state).count
                action_count + goals_not_achieved_count
              end,
              beam_width: beam_width)
  return unless sol
  sol.select { |desc| is_action?(desc) }
end

def is_action?(desc)
  desc.start_with?("Execute ")
end

def gps_successor(ops)
  Proc.new do |state|
    applicable_ops(ops, state).map do |op|
      state + op.add_list - op.del_list
    end
  end
end

def applicable_ops(ops, state)
  ops.select{ |op| (op.preconds - state).empty? }
end


###################################################
class Op
  attr_accessor :action, :preconds, :add_list, :del_list

  def initialize(opt = {})
    @action   = opt[:action]
    @preconds = opt[:preconds] || []
    @add_list = opt[:add_list] || []
    @del_list = opt[:del_list] || []
  end
end


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

def make_block_op(block, prev_loc, new_loc)
  Op.new({
    action: "move #{block} from #{prev_loc} to #{new_loc}",
    preconds: ["space on #{block}", "space on #{new_loc}", "#{block} on #{prev_loc}"] - ['space on table'],
    add_list: move_on(block, prev_loc, new_loc) + ["Execute move #{block} from #{prev_loc} to #{new_loc}"],
    del_list: move_on(block, new_loc, prev_loc)
  })
end

def move_on(block, prev_loc, new_loc)
  ["#{block} on #{new_loc}", "space on #{prev_loc}"] - ['space on table']
end

gps_search(start: ['c on a', 'b on table', 'a on table', 'space on b', 'space on c'],
           goals:['a on b', 'b on c', 'c on table'],
           ops: make_block_ops(['a', 'b', 'c']))
#####################################################
