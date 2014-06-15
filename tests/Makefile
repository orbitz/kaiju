CAMLP4=
OCAMLC_OPTS=-package qcheck,core,konfig
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

TEST_MODULES=konfig_props.ml

native_bin=$(NON_LIB_MODULES:%.ml=%.native)

byte_bin=$(NON_LIB_MODULES:%.ml=%.byte)

TEST_DEPS=../lib/konfig/konfig.cma ../lib/konfig/konfig.cmxa

.PHONY: all native-code byte-code test clean

all: test

clean: extra_clean

extra_clean:
	-rm -f *.native *.byte *.cmx *.cmo *.o *.cmi

# Dependencies
include ../lib/Ocamlrules.mk.in
