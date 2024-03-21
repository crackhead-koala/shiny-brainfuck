import gleam/io
import gleam/result
import gleam/int
import gleam/string
import gleam/list
import gleam/bit_array
import argv
import simplifile
import gleam/erlang
import gleam_community/ansi

pub fn main() {
  let args: List(String) = argv.load().arguments
  use #(memory, source_path) <- result.try(parse_arguments(args))

  let file = simplifile.read(source_path)
  case file {
    Ok(source) -> {
      run(source, memory)
    }
    Error(error) -> {
      print_file_error(source_path, error)
      Error(Nil)
    }
  }
}

fn parse_arguments(args: List(String)) -> Result(#(Int, String), Nil) {
  case args {
    [source_path] -> Ok(#(32, source_path))

    ["-m", memory, source_path] | ["--memory", memory, source_path] -> {
      use memory_int <- result.try(int.parse(memory))
      Ok(#(memory_int, source_path))
    }

    ["-h", ..] | ["--help", ..] -> {
      print_help()
      Error(Nil)
    }

    _ -> {
      io.print_error(
        ansi.bold(ansi.bright_red("Argument error"))
        <> ":\nbroken arguments.\n\n",
      )
      print_usage()
      Error(Nil)
    }
  }
}

fn print_help() -> Nil {
  io.print(
    "shinybf — a Brainfuck interpreter in "
    <> ansi.bright_magenta("Gleam")
    <> " ⭐️\n\n",
  )
  print_usage()
}

fn print_usage() -> Nil {
  io.print(ansi.yellow("Usage") <> ":  shinybf [options] <source-file>\n\n")
  io.print(ansi.yellow("Options") <> ":\n")
  io.print("  -h, --help      Show this help message.\n")
  io.print(
    "  -m, --memory size  Set memory size (number of cells). "
    <> "Default memory m is 32\n",
  )
}

fn print_file_error(source_path: String, error: simplifile.FileError) {
  case error {
    simplifile.Enoent ->
      io.println_error(
        ansi.bold(ansi.bright_red("File error"))
        <> ":\n"
        <> source_path
        <> ": no such file or directory",
      )
    _ -> {
      io.println_error(
        ansi.bold(ansi.bright_red("File error"))
        <> ":\n"
        <> source_path
        <> ": "
        <> string.inspect(error)
        <> " (see https://hexdocs.pm/simplifile/simplifile.html)",
      )
    }
  }
}

fn run(source: String, memory: Int) -> Result(Int, Nil) {
  let result =
    list.repeat(0, memory)
    |> do_interpret(source, _, 0)

  case result {
    Ok(#(_, _)) -> Ok(0)
    Error(Nil) -> {
      io.println_error("unexpected error ocurred.")
      Error(Nil)
    }
  }
}

fn do_interpret(
  source: String,
  memory: List(Int),
  pointer: Int,
) -> Result(#(List(Int), Int), Nil) {
  case source {
    "+" <> rest ->
      do_interpret(
        rest,
        change_list_element(memory, pointer, increment),
        pointer,
      )

    "-" <> rest ->
      do_interpret(
        rest,
        change_list_element(memory, pointer, decrement),
        pointer,
      )

    "." <> rest -> {
      use value <- result.try(list.at(memory, pointer))
      io.print(int_to_char(value))
      do_interpret(rest, memory, pointer)
    }

    ">" <> rest -> {
      let new_pointer: Int = case pointer == list.length(memory) - 1 {
        True -> 0
        False -> increment(pointer)
      }
      do_interpret(rest, memory, new_pointer)
    }

    "<" <> rest -> {
      let new_pointer: Int = case pointer == 0 {
        True -> list.length(memory) - 1
        False -> decrement(pointer)
      }
      do_interpret(rest, memory, new_pointer)
    }

    "[" <> rest -> {
      use subprogram <- result.try(find_subprogram(rest, 0, ""))
      use value <- result.try(list.at(memory, pointer))
      case value {
        0 -> {
          let len: Int = string.length(subprogram)
          do_interpret(string.drop_left(rest, len + 1), memory, pointer)
        }
        _ -> {
          use #(new_memory, new_pointer) <- result.try(do_interpret(
            subprogram,
            memory,
            pointer,
          ))
          do_interpret(source, new_memory, new_pointer)
        }
      }
    }

    // this case is unreachable, it's always handled in the previous one
    "]" <> _ -> Error(Nil)

    "," <> rest -> {
      // prompt starts at a newline
      io.print("\n")
      use line <- result.try(result.nil_error(erlang.get_line("> ")))
      use #(first_char, _) <- result.try(string.pop_grapheme(line))
      let first_char: Int = char_to_int(first_char)
      let new_memory =
        change_list_element(memory, pointer, fn(_) { first_char })
      do_interpret(rest, new_memory, pointer)
    }

    "" -> Ok(#(memory, pointer))

    _ -> do_interpret(string.drop_left(source, 1), memory, pointer)
  }
}

fn find_subprogram(
  source: String,
  unclosed_brackets: Int,
  subprogram: String,
) -> Result(String, Nil) {
  case string.pop_grapheme(source) {
    Ok(#(first, rest)) -> {
      case first {
        "]" -> {
          case unclosed_brackets {
            0 -> Ok(subprogram)
            _ -> find_subprogram(rest, unclosed_brackets - 1, subprogram <> "]")
          }
        }
        "[" -> find_subprogram(rest, unclosed_brackets + 1, subprogram <> "[")
        _ -> find_subprogram(rest, unclosed_brackets, subprogram <> first)
      }
    }
    Error(Nil) -> Error(Nil)
  }
}

fn change_list_element(
  list: List(a),
  at position: Int,
  with func: fn(a) -> a,
) -> List(a) {
  list.index_map(list, fn(el: a, idx: Int) -> a {
    case idx == position {
      True -> func(el)
      False -> el
    }
  })
}

fn increment(value: Int) -> Int {
  value + 1
}

fn decrement(value: Int) -> Int {
  value - 1
}

fn int_to_char(from: Int) -> String {
  <<from>>
  |> bit_array.to_string()
  // print a cute bug in case of a broken UTF codepoint
  |> result.unwrap("🪲")
}

fn char_to_int(from: String) -> Int {
  let codepoint =
    from
    |> string.to_utf_codepoints()
    |> list.at(0)

  case codepoint {
    Ok(value) -> string.utf_codepoint_to_int(value)
    Error(Nil) -> 0
  }
}
