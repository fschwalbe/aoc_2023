import gleam/int
import gleam/io
import gleam/result
import gleam/erlang
import gleam/erlang/atom.{type Atom}
import gleam/dynamic.{type Dynamic}
import gleam/string
import simplifile

pub fn main() {
  case run() {
    Ok(Nil) -> Nil
    Error(reason) -> io.println_error("error: " <> reason)
  }
}

fn run() -> Result(Nil, String) {
  use day <- result.try(day_arg())

  use input <- result.try(
    simplifile.read("../input/" <> int.to_string(day))
    |> result.map_error(fn(err) {
      "failed to read input file (" <> string.inspect(err) <> ")"
    }),
  )
  use _ <- result.try(time_part(day, Part1, input))
  time_part(day, Part2, input)
}

fn day_arg() {
  case erlang.start_arguments() {
    [day_arg] ->
      int.parse(day_arg)
      |> result.map_error(fn(_) {
        "expected a valid integer, found '" <> day_arg <> "'"
      })
      |> result.try(fn(day) {
        case day < 1 || day > 25 {
          True ->
            Error(
              "expected a day between 1 and 25, found " <> int.to_string(day),
            )
          False -> Ok(day)
        }
      })
    _ -> Error("expected exactly one argument")
  }
}

type Part {
  Part1
  Part2
}

fn time_part(day: Int, part: Part, input: String) -> Result(Nil, String) {
  let day = int.to_string(day)
  let module = atom.create_from_string("day" <> day)
  let part_fn = case part {
    Part1 -> "part1"
    Part2 -> "part2"
  }
  let function = atom.create_from_string(part_fn)
  let #(time, answer) = tc(module, function, [dynamic.from(input)])
  use answer <- result.map(
    dynamic.int(answer)
    |> result.map_error(fn(_) {
      day <> "." <> part_fn <> " did not return an integer"
    }),
  )
  let part = case part {
    Part1 -> "1"
    Part2 -> "2"
  }
  io.println(
    "Part " <> part <> ": " <> int.to_string(answer) <> " (took " <> int.to_string(
      time,
    ) <> " μs)",
  )
}

@external(erlang, "timer", "tc")
fn tc(module: Atom, function: Atom, args: List(Dynamic)) -> #(Int, Dynamic)
