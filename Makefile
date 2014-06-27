export OCAMLPATH:=$(PWD)/lib:$(OCAMLPATH)

.PHONY: all clean test examples install

all:
	$(MAKE) -C lib

test: all
	$(MAKE) -C lib test
	$(MAKE) -C tests test

examples: all
	$(MAKE) -C examples

install: all
	$(MAKE) -C lib/kaiju install

clean:
	$(MAKE) -C lib clean
	$(MAKE) -C tests clean
	$(MAKE) -C examples clean

