import gleam/iterator.{type Iterator} as iter
import gleam/list
import gleam/int
import gleam/result

pub fn part1(input: String) -> Int {
  let #(seeds, input) = parse_seeds(<<input:utf8>>)
  let assert Ok(min) =
    map_iter(input)
    |> iter.fold(
      from: iter.from_list(seeds),
      with: fn(nums, ranges) {
        use num <- iter.map(nums)
        list.find(
          ranges,
          fn(r) { r.source <= num && num < r.source + r.length },
        )
        |> result.map(fn(r) { num + r.dest - r.source })
        |> result.unwrap(num)
      },
    )
    |> iter.reduce(with: int.min)
  min
}

pub fn part2(_input: String) -> Int {
  0
}

type Parse(a) =
  #(a, BitArray)

type Range {
  Range(dest: Int, source: Int, length: Int)
}

fn map_iter(input: BitArray) -> Iterator(List(Range)) {
  use input <- iter.unfold(from: input)
  case input {
    <<>> -> iter.Done
    _ -> {
      let #(ranges, input) = parse_map(input)
      iter.Next(element: ranges, accumulator: input)
    }
  }
}

fn parse_seeds(input: BitArray) -> Parse(List(Int)) {
  let assert <<"seeds: ":utf8, input:bytes>> = input
  do_parse_seeds(input, [])
}

fn do_parse_seeds(input: BitArray, seeds: List(Int)) -> Parse(List(Int)) {
  case input {
    <<"\n\n":utf8, input:bytes>> -> #(seeds, input)
    <<" ":utf8, input:bytes>> | input -> {
      let #(seed, input) = parse_unsigned(input)
      do_parse_seeds(input, [seed, ..seeds])
    }
  }
}

fn parse_map(input: BitArray) -> Parse(List(Range)) {
  let input = skip_header(input)
  do_parse_map(input, [])
}

fn do_parse_map(input: BitArray, ranges: List(Range)) -> Parse(List(Range)) {
  case input {
    <<>> as input | <<"\n":utf8, input:bytes>> -> #(ranges, input)
    _ -> {
      let #(dest, input) = parse_unsigned(input)
      let input = assert_space(input)
      let #(source, input) = parse_unsigned(input)
      let input = assert_space(input)
      let #(length, input) = parse_unsigned(input)
      let assert <<"\n":utf8, input:bytes>> = input
      do_parse_map(input, [Range(dest, source, length), ..ranges])
    }
  }
}

fn skip_header(input: BitArray) -> BitArray {
  case input {
    <<" map:\n":utf8, input:bytes>> -> input
    <<_:8, input:bytes>> -> skip_header(input)
    _ -> panic("unexpected end of input, header not found")
  }
}

fn assert_space(input: BitArray) -> BitArray {
  let assert <<" ":utf8, input:bytes>> = input
  input
}

fn parse_unsigned(input: BitArray) -> Parse(Int) {
  do_parse_unsigned(input, 0)
}

fn do_parse_unsigned(input: BitArray, acc: Int) -> Parse(Int) {
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      do_parse_unsigned(tail, acc * 10 + b - 48)
    _ -> #(acc, input)
  }
}
