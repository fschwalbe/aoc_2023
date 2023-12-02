import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/erlang
import gleam/string
import simplifile
import day1
import day2

pub fn main() {
  case run() {
    Ok(Nil) -> Nil
    Error(reason) -> io.println_error("error: " <> reason)
  }
}

fn run() {
  use day <- result.try(day_arg())

  let days = [Day(day1.part1, day1.part2), Day(day2.part1, day2.part2)]
  use day_impl <- result.try(
    list.at(days, day - 1)
    |> result.map_error(fn(_) { "no solution for day " <> int.to_string(day) }),
  )

  use input <- result.map(
    simplifile.read("../input/" <> int.to_string(day))
    |> result.map_error(fn(err) {
      "failed to read input file (" <> string.inspect(err) <> ")"
    }),
  )

  io.print("Part 1: ")
  io.println(int.to_string(day_impl.part1(input)))
  io.print("Part 2: ")
  io.println(int.to_string(day_impl.part2(input)))
}

fn day_arg() {
  case erlang.start_arguments() {
    [day_arg] ->
      int.parse(day_arg)
      |> result.map_error(fn(_) {
        "expected a valid integer, found '" <> day_arg <> "'"
      })
    _ -> Error("expected exactly one argument")
  }
}

type Day {
  Day(part1: fn(String) -> Int, part2: fn(String) -> Int)
}
