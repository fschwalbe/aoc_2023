import gleam/list
import gleam/iterator.{type Iterator}
import gleam/dict.{type Dict}
import gleam/bool
import gleam/int
import gleam_community/maths/arithmetics

type Parse(a) =
  #(a, BitArray)

type Instruction {
  Left
  Right
}

type Node {
  Node(label: Int, left: Int, right: Int)
}

pub fn part1(input: String) -> Int {
  let #(instructions, nodes) = parse(input)

  let assert <<aaa:24>> = <<"AAA":utf8>>
  let assert <<zzz:24>> = <<"ZZZ":utf8>>
  end_index(aaa, instructions, nodes, fn(n) { n == zzz })
}

// This is probably one of the worst AoC parts ever. The puzzle did not state
// any of the important assumptions that were required to solve this in a
// sensible way.
pub fn part2(input: String) -> Int {
  let #(instructions, nodes) = parse(input)

  let assert Ok(steps) =
    nodes
    |> dict.keys
    |> list.filter(fn(node) { last_digit(node) == 65 })
    |> list.map(end_index(
      _,
      instructions,
      nodes,
      fn(node) { last_digit(node) == 90 },
    ))
    |> list.reduce(arithmetics.lcm)

  steps
}

fn last_digit(node: Int) -> Int {
  int.bitwise_and(node, 255)
}

fn end_index(
  node: Int,
  instructions: List(Instruction),
  nodes: Dict(Int, #(Int, Int)),
  is_end: fn(Int) -> Bool,
) -> Int {
  let #(_, index) =
    instructions
    |> iterator.from_list
    |> iterator.cycle
    |> iterator.fold_until(
      from: #(node, 0),
      with: fn(acc, instruction) {
        use <- bool.guard(when: is_end(acc.0), return: list.Stop(acc))
        let assert Ok(next) = dict.get(nodes, acc.0)
        list.Continue(#(
          case instruction {
            Left -> next.0
            Right -> next.1
          },
          acc.1 + 1,
        ))
      },
    )
  index
}

fn parse(input: String) -> #(List(Instruction), Dict(Int, #(Int, Int))) {
  let #(instructions, input) = parse_instructions(<<input:utf8>>, [])
  let nodes =
    parse_nodes(input)
    |> iterator.fold(
      dict.new(),
      fn(d, node) { dict.insert(d, node.label, #(node.left, node.right)) },
    )
  #(instructions, nodes)
}

fn parse_instructions(
  input: BitArray,
  acc: List(Instruction),
) -> Parse(List(Instruction)) {
  case input {
    <<"L":utf8, tail:bytes>> -> parse_instructions(tail, [Left, ..acc])
    <<"R":utf8, tail:bytes>> -> parse_instructions(tail, [Right, ..acc])
    <<"\n\n":utf8, tail:bytes>> -> #(list.reverse(acc), tail)
    _ -> panic as "expected L, R or double newline"
  }
}

fn parse_nodes(input: BitArray) -> Iterator(Node) {
  use input <- iterator.unfold(input)
  case input {
    <<>> -> iterator.Done
    <<
      label:24,
      " = (":utf8,
      left:24,
      ", ":utf8,
      right:24,
      ")\n":utf8,
      tail:bytes,
    >> -> iterator.Next(element: Node(label, left, right), accumulator: tail)
  }
}
