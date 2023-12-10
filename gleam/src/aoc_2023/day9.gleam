import gleam/iterator.{type Iterator}
import gleam/list
import gleam/int
import gleam/result
import gleam/bool
import gleam/function

type Parse(a) =
  #(a, BitArray)

type Direction {
  /// The first history element is on the left
  LtR
  /// The first history element is on the right (the end of the list)
  RtL
}

pub fn part1(input: String) -> Int {
  input
  |> histories
  |> iterator.map(first_diffs(_, RtL))
  |> iterator.flatten
  |> iterator.reduce(int.add)
  |> result.unwrap(0)
}

pub fn part2(input: String) -> Int {
  input
  |> histories
  |> iterator.map(
    list.reverse
    |> function.compose(first_diffs(_, LtR))
    |> function.compose(iterator.to_list)
    |> function.compose(list.reverse)
    |> function.compose(list.fold(_, 0, function.flip(int.subtract))),
  )
  |> iterator.reduce(int.add)
  |> result.unwrap(0)
}

fn first_diffs(history: List(Int), direction: Direction) -> Iterator(Int) {
  iterator.unfold(
    history,
    fn(d) {
      use <- bool.guard(
        when: list.all(d, fn(n) { n == 0 }),
        return: iterator.Done,
      )
      d
      |> list.window_by_2
      |> list.map(fn(pair) {
        case direction {
          LtR -> pair.1 - pair.0
          RtL -> pair.0 - pair.1
        }
      })
      |> fn(next) { iterator.Next(element: d, accumulator: next) }
    },
  )
  |> iterator.map(fn(d) {
    let assert [a, ..] = d
    a
  })
}

fn histories(input: String) -> Iterator(List(Int)) {
  use input <- iterator.unfold(<<input:utf8>>)
  case input {
    <<>> -> iterator.Done
    _ -> {
      let #(history, input) = parse_history(input, [])
      iterator.Next(element: history, accumulator: input)
    }
  }
}

fn parse_history(input: BitArray, acc: List(Int)) -> Parse(List(Int)) {
  case input {
    <<"\n":utf8, tail:bytes>> -> #(acc, tail)
    <<" ":utf8, input:bytes>> | _ as input -> {
      let #(num, input) = parse_int(input)
      parse_history(input, [num, ..acc])
    }
  }
}

fn parse_int(input: BitArray) -> Parse(Int) {
  case input {
    <<"-":utf8, tail:bytes>> -> {
      let #(num, tail) = do_parse_int(tail, 0)
      #(-num, tail)
    }
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 -> do_parse_int(tail, b - 48)
    _ -> panic as "expected integer"
  }
}

fn do_parse_int(input: BitArray, acc: Int) -> Parse(Int) {
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      do_parse_int(tail, acc * 10 + b - 48)
    _ -> #(acc, input)
  }
}
