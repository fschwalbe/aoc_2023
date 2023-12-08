import gleam/list
import gleam/iterator.{type Iterator}
import gleam/dict
import gleam/bool

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
  let #(instructions, input) = parse_instructions(<<input:utf8>>, [])
  let nodes =
    parse_nodes(input)
    |> iterator.fold(
      dict.new(),
      fn(d, node) { dict.insert(d, node.label, #(node.left, node.right)) },
    )

  let assert <<aaa:24>> = <<"AAA":utf8>>
  let assert <<zzz:24>> = <<"ZZZ":utf8>>
  let #(_, steps) =
    instructions
    |> iterator.from_list
    |> iterator.cycle
    |> iterator.fold_until(
      from: #(aaa, 0),
      with: fn(acc, instruction) {
        use <- bool.guard(when: acc.0 == zzz, return: list.Stop(acc))
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

  steps
}

pub fn part2(_input: String) -> Int {
  0
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
