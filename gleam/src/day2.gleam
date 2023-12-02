pub fn part1(input: String) -> Int {
  fold_games(0, 1, <<input:utf8>>)
}

fn fold_games(sum: Int, index: Int, input: BitArray) -> Int {
  let assert <<"Game ":utf8, input:bytes>> = input
  // skip index, colon and space
  let input = drop_until(input, 32)
  let #(possible, input) = cubes(input)
  let sum = case possible {
    True -> sum + index
    False -> sum
  }
  case input {
    <<>> -> sum
    _ -> fold_games(sum, index + 1, input)
  }
}

fn cubes(input: BitArray) -> #(Bool, BitArray) {
  let #(num, input) = parse_unsigned(input)
  let #(max, tail) = case input {
    <<"red":utf8, tail:bytes>> -> #(12, tail)
    <<"green":utf8, tail:bytes>> -> #(13, tail)
    <<"blue":utf8, tail:bytes>> -> #(14, tail)
  }
  case num <= max {
    True ->
      case tail {
        <<"\n":utf8, tail:bytes>> -> #(True, tail)
        <<_:8, " ":utf8, tail:bytes>> -> cubes(tail)
      }
    // drop until newline
    False -> #(False, drop_until(tail, 10))
  }
}

fn drop_until(bytes: BitArray, byte: Int) -> BitArray {
  case bytes {
    <<>> -> <<>>
    <<b:8, tail:bytes>> ->
      case b == byte {
        True -> tail
        False -> drop_until(tail, byte)
      }
  }
}

fn parse_unsigned(string: BitArray) -> #(Int, BitArray) {
  do_parse_unsigned(0, string)
}

fn do_parse_unsigned(acc: Int, string: BitArray) -> #(Int, BitArray) {
  case string {
    <<>> -> #(acc, <<>>)
    <<b:8, tail:bytes>> ->
      case b >= 48 && b <= 57 {
        True -> do_parse_unsigned(acc * 10 + b - 48, tail)
        False -> #(acc, tail)
      }
  }
}

pub fn part2(input: String) -> Int {
  0
}
