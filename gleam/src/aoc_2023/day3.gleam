import gleam/int
import gleam/list
import gleam/order

pub fn part1(input: String) -> Int {
  fold_lines(
    <<input:utf8>>,
    0,
    fn(sum, prev, curr) {
      let Part1Line(_, curr, sum) =
        list.fold(curr, Part1Line(prev, [], sum), part1_fold_line)
      #(sum, list.reverse(curr))
    },
  )
}

type Part1Line {
  Part1Line(prev: List(Item), rem: List(Item), sum: Int)
}

fn part1_fold_line(acc: Part1Line, curr: Item) -> Part1Line {
  let Part1Line(prev, rem, sum) = acc
  case curr {
    Num(from, to, value) -> {
      let CheckNum(prev, matches) = check_prev_num(prev, from, to)

      let left_idx = from - 1
      let matches =
        matches || case rem {
          [Sym(sym_idx, _), ..] if sym_idx == left_idx -> True
          _ -> False
        }

      case matches {
        True -> Part1Line(prev, rem, sum + value)
        False -> Part1Line(prev, [curr, ..rem], sum)
      }
    }
    Sym(idx, _) -> {
      let CheckSym(prev, values) = check_prev_sym(prev, idx)

      let left_idx = idx - 1
      let #(rem, sum) = case rem {
        [Num(_, to, value), ..tail] if to == left_idx -> #(tail, sum + value)
        _ -> #(rem, sum)
      }

      Part1Line(prev, [curr, ..rem], sum + values)
    }
  }
}

type Item {
  Num(from: Int, to: Int, value: Int)
  Sym(idx: Int, value: Int)
}

type CheckNum {
  CheckNum(prev: List(Item), num_matches: Bool)
}

fn check_prev_num(prev: List(Item), from: Int, to: Int) -> CheckNum {
  case prev {
    [Num(to: prev_to, ..), ..tail] if prev_to < to ->
      check_prev_num(tail, from, to)
    // one index lookahead because of the diagonal-crossed pattern
    [Num(to: prev_to, ..), ..tail] if prev_to == to -> {
      case tail {
        [Sym(idx, _), ..] -> CheckNum(prev, idx == to + 1)
        _ -> CheckNum(prev, False)
      }
    }
    [Sym(idx, _), ..tail] ->
      case idx < from - 1 {
        True -> check_prev_num(tail, from, to)
        False if idx < to -> CheckNum(tail, True)
        False -> CheckNum(prev, idx <= to + 1)
      }
    _ -> CheckNum(prev, False)
  }
}

type CheckSym {
  CheckSym(prev: List(Item), sum: Int)
}

fn check_prev_sym(prev: List(Item), idx: Int) -> CheckSym {
  do_check_prev_sym(prev, idx, 0)
}

fn do_check_prev_sym(prev: List(Item), idx: Int, sum: Int) -> CheckSym {
  case prev {
    [] -> CheckSym([], sum)
    [Num(from, to, value), ..tail] ->
      case idx > to + 1 {
        True -> do_check_prev_sym(tail, idx, sum)
        False ->
          case idx < from - 1 {
            True -> CheckSym(prev, sum)
            False -> do_check_prev_sym(tail, idx, sum + value)
          }
      }
    [Sym(prev_idx, _) as sym, ..tail] ->
      case int.compare(prev_idx, idx) {
        order.Lt -> do_check_prev_sym(tail, idx, sum)
        // one index lookahead like above
        order.Eq ->
          case tail {
            [Num(from, _, value), ..tail] ->
              case from == idx + 1 {
                True -> CheckSym([sym, ..tail], sum + value)
                False -> CheckSym(prev, sum)
              }
          }
        order.Gt -> CheckSym(prev, sum)
      }
  }
}

pub fn part2(input: String) -> Int {
  let #(sum, last) =
    fold_lines(
      <<input:utf8>>,
      #(0, []),
      fn(acc, prev, curr) {
        let #(sum, _) = acc
        let Part2Line(prev, curr) =
          list.fold(curr, Part2Line(prev, []), part2_fold_line)
        let sum = sum + sum_valid_gears(prev)
        let curr = list.reverse(curr)
        #(#(sum, curr), curr)
      },
    )
  sum + sum_valid_gears(last)
}

fn sum_valid_gears(items: List(Item2)) -> Int {
  list.fold(
    items,
    0,
    fn(sum, item) {
      sum + case item {
        Gear(_, [a, b]) -> a * b
        _ -> 0
      }
    },
  )
}

fn part2_fold_line(acc: Part2Line, curr: Item) -> Part2Line {
  let Part2Line(prev, rem) = acc
  case curr {
    Num(from, to, value) -> {
      let prev =
        list.filter_map(
          prev,
          fn(prev) {
            case prev {
              Gear(idx, adjacent) ->
                case idx >= from - 1 && idx <= to + 1 {
                  True -> add_adjacent(idx, adjacent, value)
                  False -> Ok(prev)
                }
              _ -> Ok(prev)
            }
          },
        )

      let left_idx = from - 1
      let rem = case rem {
        [Gear(idx, adjacent), ..tail] if idx == left_idx ->
          case add_adjacent(idx, adjacent, value) {
            Ok(gear) -> [gear, ..tail]
            Error(_) -> tail
          }
        _ -> rem
      }

      Part2Line(prev, [Num2(from, to, value), ..rem])
    }
    Sym(idx, 42) -> {
      let adjacent =
        list.filter_map(
          prev,
          fn(prev) {
            case prev {
              Num2(from, to, value) ->
                case idx >= from - 1 && idx <= to + 1 {
                  True -> Ok(value)
                  False -> Error(Nil)
                }
              _ -> Error(Nil)
            }
          },
        )

      let left_idx = idx - 1
      let adjacent = case rem {
        [Num2(_, to, value), ..] if to == left_idx -> [value, ..adjacent]
        _ -> adjacent
      }

      Part2Line(
        prev,
        case list.length(adjacent) <= 2 {
          True -> [Gear(idx, adjacent), ..rem]
          False -> rem
        },
      )
    }
    _ -> acc
  }
}

fn add_adjacent(idx: Int, adjacent: List(Int), value: Int) -> Result(Item2, Nil) {
  case list.length(adjacent) < 2 {
    True -> Ok(Gear(idx, [value, ..adjacent]))
    False -> Error(Nil)
  }
}

type Item2 {
  Gear(idx: Int, adjacent: List(Int))
  Num2(from: Int, to: Int, value: Int)
}

type Part2Line {
  Part2Line(prev: List(Item2), rem: List(Item2))
}

fn fold_lines(
  input: BitArray,
  initial: a,
  fun: fn(a, List(b), List(Item)) -> #(a, List(b)),
) -> a {
  do_fold_lines(input, initial, [], fun)
}

fn do_fold_lines(
  input: BitArray,
  acc: a,
  prev: List(b),
  fun: fn(a, List(b), List(Item)) -> #(a, List(b)),
) {
  case input {
    <<>> -> acc
    _ -> {
      let #(curr, input) = parse_line(input)
      let #(acc, curr) = fun(acc, prev, curr)
      do_fold_lines(input, acc, curr, fun)
    }
  }
}

fn parse_line(input: BitArray) -> #(List(Item), BitArray) {
  do_parse_line(input, [], 0)
}

fn do_parse_line(
  input: BitArray,
  curr: List(Item),
  idx: Int,
) -> #(List(Item), BitArray) {
  case input {
    <<>> as tail | <<"\n":utf8, tail:bytes>> -> #(list.reverse(curr), tail)
    <<".":utf8, tail:bytes>> -> do_parse_line(tail, curr, idx + 1)
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 -> {
      let #(value, after_idx, tail) = parse_unsigned(b - 48, idx + 1, tail)
      do_parse_line(tail, [Num(idx, after_idx - 1, value), ..curr], after_idx)
    }
    <<b:8, tail:bytes>> -> do_parse_line(tail, [Sym(idx, b), ..curr], idx + 1)
  }
}

fn parse_unsigned(acc: Int, idx: Int, input: BitArray) -> #(Int, Int, BitArray) {
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      parse_unsigned(acc * 10 + b - 48, idx + 1, tail)
    _ -> #(acc, idx, input)
  }
}
