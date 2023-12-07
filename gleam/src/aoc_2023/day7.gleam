import gleam/iterator.{type Iterator}
import gleam/list
import gleam/dict
import gleam/option
import gleam/int
import gleam/order
import gleam/bool

type Parse(a) =
  #(a, BitArray)

type Hand {
  Hand(cards: List(Int), bid: Int)
}

type HandStrength {
  HandStrength(major: Int, minor: Int, bid: Int)
}

pub fn part1(input: String) -> Int {
  solve(input, jokers: False)
}

pub fn part2(input: String) -> Int {
  solve(input, jokers: True)
}

fn solve(input: String, jokers jokers: Bool) {
  parse(<<input:utf8>>, jokers)
  |> iterator.map(fn(hand) {
    let assert Ok(minor) = int.undigits(hand.cards, 13)
    let #(cards, joker_count) = case jokers {
      False -> #(hand.cards, 0)
      True -> {
        let cards = list.filter(hand.cards, fn(c) { c != 0 })
        #(cards, list.length(hand.cards) - list.length(cards))
      }
    }
    HandStrength(major_strength(cards, joker_count), minor, hand.bid)
  })
  |> iterator.to_list
  |> list.sort(fn(a, b) {
    case int.compare(a.major, b.major) {
      order.Eq -> int.compare(a.minor, b.minor)
      o -> o
    }
  })
  |> list.index_fold(0, fn(sum, hand, index) { sum + hand.bid * { index + 1 } })
}

fn major_strength(cards: List(Int), jokers: Int) -> Int {
  let counts =
    list.fold(
      over: cards,
      from: dict.new(),
      with: fn(counts, card) {
        dict.update(counts, card, fn(count) { option.unwrap(count, 0) + 1 })
      },
    )
  case dict.size(counts) {
    1 | 0 -> 6
    2 -> {
      let assert Ok(max) =
        counts
        |> dict.values
        |> list.reduce(int.max)
      max + jokers + 1
    }
    3 -> {
      let assert Ok(max) =
        counts
        |> dict.values
        |> list.reduce(int.max)
      max + jokers
    }
    4 -> 1
    5 -> 0
  }
}

fn parse(input: BitArray, jokers: Bool) -> Iterator(Hand) {
  use input <- iterator.unfold(input)
  case input {
    <<>> -> iterator.Done
    _ -> {
      let #(cards, input) = parse_cards(input, jokers, [])
      let #(bid, input) = parse_bid(input, 0)
      iterator.Next(element: Hand(cards, bid), accumulator: input)
    }
  }
}

fn parse_cards(
  input: BitArray,
  jokers: Bool,
  cards: List(Int),
) -> Parse(List(Int)) {
  case input {
    <<"A":utf8, tail:bytes>> -> parse_cards(tail, jokers, [12, ..cards])
    <<"K":utf8, tail:bytes>> -> parse_cards(tail, jokers, [11, ..cards])
    <<"Q":utf8, tail:bytes>> -> parse_cards(tail, jokers, [10, ..cards])
    <<"J":utf8, tail:bytes>> -> {
      let num = case jokers {
        False -> 9
        True -> 0
      }
      parse_cards(tail, jokers, [num, ..cards])
    }
    <<"T":utf8, tail:bytes>> ->
      parse_cards(tail, jokers, [8 + bool.to_int(jokers), ..cards])
    <<b:8, tail:bytes>> if b >= 50 && b <= 57 ->
      parse_cards(tail, jokers, [b - 50 + bool.to_int(jokers), ..cards])
    <<" ":utf8, tail:bytes>> -> #(list.reverse(cards), tail)
    _ -> panic as "expected card or space"
  }
}

fn parse_bid(input: BitArray, acc: Int) -> Parse(Int) {
  case input {
    <<b:8, tail:bytes>> if b >= 48 && b <= 57 ->
      parse_bid(tail, acc * 10 + b - 48)
    <<"\n":utf8, tail:bytes>> -> #(acc, tail)
    _ -> panic as "expected decimal digit or newline"
  }
}
