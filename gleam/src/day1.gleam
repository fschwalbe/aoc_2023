// no type import syntax because it breaks helix syntax highlighting
import gleam/option.{None, Option, Some}

pub fn part1(input: String) -> Int {
  do_part1(0, None, None, <<input:utf8>>)
}

fn do_part1(
  sum: Int,
  first: Option(Int),
  last: Option(Int),
  remaining: BitArray,
) {
  case remaining {
    <<>> -> sum
    <<"\n":utf8, tail:bytes>> -> {
      let assert Some(f) = first
      let l = option.unwrap(last, f)
      do_part1(10 * f + l + sum, None, None, tail)
    }
    <<b:8, tail:bytes>> ->
      case b >= 48 && b <= 57 {
        True -> {
          let digit = Some(b - 48)
          do_part1(sum, option.or(first, digit), digit, tail)
        }
        False -> do_part1(sum, first, last, tail)
      }
  }
}

pub fn part2(input: String) -> Int {
  do_part2(0, None, None, <<input:utf8>>)
}

fn do_part2(
  sum: Int,
  first: Option(Int),
  last: Option(Int),
  remaining: BitArray,
) {
  let next_digit = fn(digit, len) {
    let assert <<_:size(len)-unit(8), tail:bytes>> = remaining
    do_part2(sum, option.or(first, Some(digit)), Some(digit), tail)
  }
  case remaining {
    <<>> -> sum + option.unwrap(first, 0) * 10 + option.unwrap(last, 0)
    <<"\n":utf8, tail:bytes>> -> {
      let assert Some(f) = first
      let l = option.unwrap(last, f)
      do_part2(10 * f + l + sum, None, None, tail)
    }
    <<"one":utf8, _:bytes>> -> next_digit(1, 2)
    <<"two":utf8, _:bytes>> -> next_digit(2, 2)
    <<"three":utf8, _:bytes>> -> next_digit(3, 4)
    <<"four":utf8, _:bytes>> -> next_digit(4, 4)
    <<"five":utf8, _:bytes>> -> next_digit(5, 3)
    <<"six":utf8, _:bytes>> -> next_digit(6, 3)
    <<"seven":utf8, _:bytes>> -> next_digit(7, 4)
    <<"eight":utf8, _:bytes>> -> next_digit(8, 4)
    <<"nine":utf8, _:bytes>> -> next_digit(9, 3)
    <<b:8, tail:bytes>> ->
      case b >= 48 && b <= 57 {
        True -> next_digit(b - 48, 1)
        False -> do_part2(sum, first, last, tail)
      }
  }
}
