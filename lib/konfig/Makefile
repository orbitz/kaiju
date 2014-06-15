CAMLP4=

OCAMLDEP_OPTS=-package core,comparelib.syntax,sexplib.syntax -syntax camlp4o
OCAMLC_OPTS=$(OCAMLDEP_OPTS) -w '@f@p@u@s@40'
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

LIB_MODULES=konfig.ml
NON_LIB_MODULES=

BYTE_TARGETS=konfig.cma
NATIVE_TARGETS=konfig.cmxa

.PHONY: all test

all: native-code byte-code

test:

# Dependencies
include ../Ocamlrules.mk.in
