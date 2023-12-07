import gleam/int

pub fn part1(input: String) -> Int {
  sum_games(
    <<input:utf8>>,
    1,
    fn(index, input) {
      let #(possible, input) =
        fold_cubes(
          input,
          True,
          fn(possible, num, color) {
            possible && num <= case color {
              Red -> 12
              Green -> 13
              Blue -> 14
            }
          },
        )
      let value = case possible {
        True -> index
        False -> 0
      }
      #(index + 1, value, input)
    },
  )
}

pub fn part2(input: String) -> Int {
  sum_games(
    <<input:utf8>>,
    Nil,
    fn(_, input) {
      let #(req, input) =
        fold_cubes(
          input,
          Req(0, 0, 0),
          fn(req, num, color) {
            case color {
              Red -> Req(..req, red: int.max(req.red, num))
              Green -> Req(..req, green: int.max(req.green, num))
              Blue -> Req(..req, blue: int.max(req.blue, num))
            }
          },
        )
      #(Nil, req.red * req.green * req.blue, input)
    },
  )
}

type Req {
  Req(red: Int, green: Int, blue: Int)
}

type Color {
  Red
  Green
  Blue
}

fn sum_games(
  input: BitArray,
  initial: a,
  fun: fn(a, BitArray) -> #(a, Int, BitArray),
) -> Int {
  do_sum_games(0, input, initial, fun)
}

fn do_sum_games(
  sum: Int,
  input: BitArray,
  initial: a,
  fun: fn(a, BitArray) -> #(a, Int, BitArray),
) -> Int {
  let assert <<"Game ":utf8, input:bytes>> = input
  // skip index, colon and space
  let input = drop_until(input, 32)
  let #(initial, num, input) = fun(initial, input)
  let sum = sum + num
  case input {
    <<>> -> sum
    _ -> do_sum_games(sum, input, initial, fun)
  }
}

fn fold_cubes(
  input: BitArray,
  initial: a,
  fun: fn(a, Int, Color) -> a,
) -> #(a, BitArray) {
  let #(num, input) = parse_unsigned(input)
  let #(max, tail) = case input {
    <<"red":utf8, tail:bytes>> -> #(Red, tail)
    <<"green":utf8, tail:bytes>> -> #(Green, tail)
    <<"blue":utf8, tail:bytes>> -> #(Blue, tail)
  }
  let acc = fun(initial, num, max)
  case tail {
    <<"\n":utf8, tail:bytes>> -> #(acc, tail)
    <<_:8, " ":utf8, tail:bytes>> -> fold_cubes(tail, acc, fun)
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
