import gleam/iterator
import gleam/int
import gleam/float
import gleam/result

type Parse(a) =
  #(a, BitArray)

type Race {
  Race(time: Int, distance: Int)
}

pub fn part1(input: String) -> Int {
  solve(input, single: False)
}

pub fn part2(input: String) -> Int {
  solve(input, single: True)
}

fn solve(input: String, single single: Bool) -> Int {
  <<input:utf8>>
  |> parse(single)
  |> iterator.from_list()
  |> iterator.map(winning_choices)
  |> iterator.reduce(int.multiply)
  |> result.unwrap(0)
}

fn winning_choices(race: Race) -> Int {
  let Race(time, distance) = race
  let assert Ok(disc) = int.square_root(time * time - 4 * distance)
  let s1 = { int.to_float(time) -. disc } /. 2.0
  let s2 = { int.to_float(time) +. disc } /. 2.0
  float.round(float.floor(s2)) - float.round(float.floor(s1))
}

fn parse(input: BitArray, single: Bool) -> List(Race) {
  let assert <<"Time:":utf8, input:bytes>> = input
  let #(times, input) = parse_ints(input, single)
  let assert <<"Distance:":utf8, input:bytes>> = input
  let #(distances, _) = parse_ints(input, single)
  zip_races(times, distances, [])
}

fn zip_races(
  times: List(Int),
  distances: List(Int),
  acc: List(Race),
) -> List(Race) {
  case times, distances {
    [x, ..xs], [y, ..ys] -> zip_races(xs, ys, [Race(x, y), ..acc])
    _, _ -> acc
  }
}

fn parse_ints(input: BitArray, single: Bool) -> Parse(List(Int)) {
  do_parse_ints(input, single, [])
}

fn do_parse_ints(
  input: BitArray,
  single: Bool,
  ints: List(Int),
) -> Parse(List(Int)) {
  let input = skip_spaces(input)
  case input {
    <<"\n":utf8, input:bytes>> -> #(ints, input)
    _ -> {
      let #(int, input) = parse_unsigned(input, single)
      do_parse_ints(input, single, [int, ..ints])
    }
  }
}

fn skip_spaces(input: BitArray) -> BitArray {
  case input {
    <<" ":utf8, input:bytes>> -> skip_spaces(input)
    _ -> input
  }
}

fn parse_unsigned(input: BitArray, single: Bool) -> Parse(Int) {
  do_parse_unsigned(input, single, 0)
}

fn do_parse_unsigned(input: BitArray, single: Bool, acc: Int) -> Parse(Int) {
  let input = case single {
    True -> skip_spaces(input)
    False -> input
  }
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      do_parse_unsigned(tail, single, acc * 10 + b - 48)
    _ -> #(acc, input)
  }
}
