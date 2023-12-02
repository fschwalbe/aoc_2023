#!/usr/bin/env nu

def main [day: int] {
  http get -H [Cookie $"session=($env.AOC_SESSION_COOKIE)"] $"https://adventofcode.com/2023/day/($day)/input" |
    save $"input/($day)"
}
