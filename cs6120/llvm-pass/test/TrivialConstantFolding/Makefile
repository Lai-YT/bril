CC = clang-17
CFLAGS ?= -fpass-plugin="../../build/pass/TrivialConstantFolding/TrivialConstantFoldingPass.so"

SRC = $(wildcard *.c)
EXE = $(SRC:.c=.out)

all: $(EXE)

%.out: %.c
	$(CC) $(CFLAGS) -o $@ $<

test: $(EXE)
	@turnt $(EXE) --verbose --diff --parallel
.PHONY: test

clean:
	$(RM) $(EXE)
.PHONY: clean
