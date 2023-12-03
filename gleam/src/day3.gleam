import gleam/int
import gleam/list
import gleam/order

pub fn part1(input: String) -> Int {
  do_part1(<<input:utf8>>, [], 0)
}

fn do_part1(input: BitArray, prev: List(Item), sum: Int) -> Int {
  case input {
    <<>> -> sum
    _ -> {
      let #(line_sum, prev, input) = parse_line(input, prev)
      do_part1(input, prev, sum + line_sum)
    }
  }
}

type Item {
  Num(from: Int, to: Int, value: Int)
  Sym(idx: Int)
}

fn parse_line(input: BitArray, prev: List(Item)) -> #(Int, List(Item), BitArray) {
  do_parse_line(input, prev, [], 0, 0)
}

fn do_parse_line(
  input: BitArray,
  prev: List(Item),
  curr: List(Item),
  idx: Int,
  sum: Int,
) -> #(Int, List(Item), BitArray) {
  let left_idx = idx - 1
  case input {
    <<>> as tail | <<"\n":utf8, tail:bytes>> -> #(sum, list.reverse(curr), tail)
    <<".":utf8, tail:bytes>> -> do_parse_line(tail, prev, curr, idx + 1, sum)
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 -> {
      let #(num, after_idx, tail) = parse_unsigned(b - 48, idx + 1, tail)

      let CheckNum(prev, matches) = check_prev_num(prev, idx, after_idx - 1)

      let matches =
        matches || case curr {
          [Sym(sym_idx), ..] if sym_idx == left_idx -> True
          _ -> False
        }

      case matches {
        True -> do_parse_line(tail, prev, curr, after_idx, sum + num)
        False ->
          do_parse_line(
            tail,
            prev,
            [Num(idx, after_idx - 1, num), ..curr],
            after_idx,
            sum,
          )
      }
    }

    <<_:8, tail:bytes>> -> {
      let #(curr, sum) = case curr {
        [Num(_, to, value), ..rest] if to == left_idx -> #(rest, sum + value)
        _ -> #(curr, sum)
      }
      let CheckSym(prev, values) = check_prev_sym(prev, idx)
      do_parse_line(tail, prev, [Sym(idx), ..curr], idx + 1, sum + values)
    }
  }
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
        [Sym(idx), ..] -> CheckNum(prev, idx == to + 1)
        _ -> CheckNum(prev, False)
      }
    }
    [Sym(idx), ..tail] ->
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
    [Sym(prev_idx) as sym, ..tail] ->
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

fn parse_unsigned(acc: Int, idx: Int, input: BitArray) -> #(Int, Int, BitArray) {
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      parse_unsigned(acc * 10 + b - 48, idx + 1, tail)
    _ -> #(acc, idx, input)
  }
}

pub fn part2(_input: String) -> Int {
  0
}
