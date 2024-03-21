.PHONY: all

all:
	gleam run -m gleescript
	cp ./shiny_brainfuck ./bin/shinybf
	rm ./shiny_brainfuck
	chmod +x ./bin/shinybf
