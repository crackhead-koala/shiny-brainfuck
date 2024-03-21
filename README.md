# Shiny Brainfuck ⭐️🧠

A [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) interpreter in [Gleam ⭐️](https://gleam.run/)!

This is not a serious project (duh...), just a small exercise for me to learn Gleam. Thus, the interpreter is implemented in the most straightforward way possible, with no optimizations at all. Try running the `mandelbrot.b` program from the examples folder in [this interpreter](https://copy.sh/brainfuck/?file=https://copy.sh/brainfuck/prog/mandelbrot.b) and then in mine to see what I mean ☠️🤹🏻🙈 (Heads up: it needs 512 cells of memory to work.)

## Quick Start

```shell
$ ./bin/shinybf -h
shinybf — a Brainfuck interpreter in Gleam ⭐️

Usage:  shinybf [options] <source-file>

Options:
  -h, --help      Show this help message.
  -m, --memory m  Set memory size (number of cells). Default memory size is 32

$ ./bin/shinybf ./examples/hello.b
Hello World!
```

## How to Use

A pre-built binary is provided in `bin/shinybf`. You can also build the executable file yourself with

```shell
$ make all
gleam run -m gleescript
   Compiled in 0.01s
    Running gleescript.main
  Generated ./shiny_brainfuck
cp ./shiny_brainfuck ./bin/shinybf
rm ./shiny_brainfuck
chmod +x ./bin/shinybf
```

Or, alternatively, you can run the source directly

```shell
$ gleam run -- -m 8 ./examples/hello.b
   Compiled in 0.01s
    Running shiny_brainfuck.main
Hello World!
```
