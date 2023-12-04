import gleam/dict.{Dict}
import gleam/set.{Set}
import gleam/list
import gleam/iterator as iter
import gleam/bool
import gleam/int
import gleam/option

pub fn part1(input: String) -> Int {
  fold_cards(
    <<input:utf8>>,
    0,
    fn(sum, card) { sum + int.bitwise_shift_left(1, matches(card) - 1) },
  )
}

pub fn part2(input: String) -> Int {
  let #(counts, _) = fold_cards(<<input:utf8>>, #(dict.new(), 0), fold_part2)
  dict.fold(counts, 0, fn(sum, _, count) { sum + count })
}

fn fold_part2(acc: #(Dict(Int, Int), Int), card: Card) -> #(Dict(Int, Int), Int) {
  let #(counts, idx) = acc
  let matches = matches(card)

  let counts = dict.update(counts, idx, fn(count) { option.unwrap(count, 1) })
  let assert Ok(this_count) = dict.get(counts, idx)

  // proof that exclusive ranges are superior
  let counts = {
    use <- bool.guard(matches == 0, counts)
    iter.range(idx + 1, idx + matches)
    |> iter.fold(
      counts,
      fn(counts, idx) {
        dict.update(
          counts,
          idx,
          fn(count) { option.unwrap(count, 1) + this_count },
        )
      },
    )
  }
  #(counts, idx + 1)
}

type Card {
  Card(winning: Set(Int), own: List(Int))
}

fn matches(card: Card) -> Int {
  set.take(from: card.winning, keeping: card.own)
  |> set.size
}

fn fold_cards(input: BitArray, initial: a, fun: fn(a, Card) -> a) {
  case input {
    <<>> -> initial
    _ -> {
      let #(card, input) = parse_card(input)
      let acc = fun(initial, card)
      fold_cards(input, acc, fun)
    }
  }
}

fn parse_card(input: BitArray) -> #(Card, BitArray) {
  let assert <<"Card ":utf8, input:bytes>> = input
  let input = skip_spaces(input)
  let #(_, input) = parse_unsigned(input)
  let assert <<":":utf8, input:bytes>> = input
  let input = skip_spaces(input)
  let #(winning, input) = parse_winning(input)
  let #(own, input) = parse_own(input)
  #(Card(winning, own), input)
}

fn parse_winning(input: BitArray) -> #(Set(Int), BitArray) {
  do_parse_winning(input, set.new())
}

fn do_parse_winning(input: BitArray, winning: Set(Int)) -> #(Set(Int), BitArray) {
  let input = skip_spaces(input)
  case input {
    <<"|":utf8, tail:bytes>> -> #(winning, tail)
    _ -> {
      let #(num, input) = parse_unsigned(input)
      do_parse_winning(input, set.insert(winning, num))
    }
  }
}

fn parse_own(input: BitArray) -> #(List(Int), BitArray) {
  do_parse_own(input, [])
}

fn do_parse_own(input: BitArray, own: List(Int)) -> #(List(Int), BitArray) {
  let input = skip_spaces(input)
  case input {
    <<"\n":utf8, tail:bytes>> -> #(list.reverse(own), tail)
    _ -> {
      let #(num, input) = parse_unsigned(input)
      do_parse_own(input, [num, ..own])
    }
  }
}

fn skip_spaces(input: BitArray) -> BitArray {
  case input {
    <<" ":utf8, tail:bytes>> -> skip_spaces(tail)
    _ -> input
  }
}

fn parse_unsigned(input: BitArray) -> #(Int, BitArray) {
  do_parse_unsigned(input, 0)
}

fn do_parse_unsigned(input: BitArray, acc: Int) -> #(Int, BitArray) {
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      do_parse_unsigned(tail, acc * 10 + b - 48)
    _ -> #(acc, input)
  }
}
