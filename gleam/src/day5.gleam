import gleam/iterator.{type Iterator} as iter
import gleam/list
import gleam/bool
import gleam/int
import gleam/result

type Parse(a) =
  #(a, BitArray)

type Range {
  Range(start: Int, length: Int)
}

type Mapping {
  Mapping(dest: Int, source: Int, length: Int)
}

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
          fn(m) { m.source <= num && num < m.source + m.length },
        )
        |> result.map(fn(r) { num + r.dest - r.source })
        |> result.unwrap(num)
      },
    )
    |> iter.reduce(with: int.min)
  min
}

pub fn part2(input: String) -> Int {
  let #(seeds, input) = parse_seeds(<<input:utf8>>)
  let assert Ok(min) =
    iter.from_list(seeds)
    |> iter.sized_chunk(2)
    |> iter.map(fn(pair) {
      // backwards because list was built backwards during parsing
      let assert [length, start] = pair
      Range(start, length)
    })
    |> iter.fold(
      over: map_iter(input),
      from: _,
      with: fn(ranges: Iterator(Range), mappings) {
        let mappings =
          list.sort(mappings, fn(a, b) { int.compare(a.source, b.source) })
        iter.flat_map(ranges, map_range(_, mappings))
      },
    )
    |> iter.map(fn(r) { r.start })
    |> iter.reduce(with: int.min)
  min
}

fn map_range(range: Range, mappings: List(Mapping)) -> Iterator(Range) {
  use <- bool.guard(when: range.length <= 0, return: iter.empty())

  case list.drop_while(mappings, fn(m) { m.source + m.length <= range.start }) {
    [] -> iter.single(range)
    [m, ..] as mappings -> {
      case m.source <= range.start {
        True -> {
          let #(first, rest) =
            split_range(range, m.length + m.source - range.start)
          use <- iter.yield(Range(first.start + m.dest - m.source, first.length))
          map_range(rest, mappings)
        }
        False -> {
          let #(first, rest) = split_range(range, m.source - range.start)
          use <- iter.yield(first)
          map_range(rest, mappings)
        }
      }
    }
  }
}

fn split_range(range: Range, at: Int) -> #(Range, Range) {
  let at = int.clamp(at, min: 0, max: range.length)
  #(Range(range.start, at), Range(range.start + at, range.length - at))
}

fn map_iter(input: BitArray) -> Iterator(List(Mapping)) {
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

fn parse_map(input: BitArray) -> Parse(List(Mapping)) {
  let input = skip_header(input)
  do_parse_map(input, [])
}

fn do_parse_map(input: BitArray, ranges: List(Mapping)) -> Parse(List(Mapping)) {
  case input {
    <<>> as input | <<"\n":utf8, input:bytes>> -> #(ranges, input)
    _ -> {
      let #(dest, input) = parse_unsigned(input)
      let input = assert_space(input)
      let #(source, input) = parse_unsigned(input)
      let input = assert_space(input)
      let #(length, input) = parse_unsigned(input)
      let assert <<"\n":utf8, input:bytes>> = input
      do_parse_map(input, [Mapping(dest, source, length), ..ranges])
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
