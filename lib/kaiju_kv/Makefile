CAMLP4=

OCAMLDEP_OPTS=-package core,async,zolog,konfig
OCAMLC_OPTS=$(OCAMLDEP_OPTS) -w '@f@p@u@s@40'
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

LIB_MODULES=kaiju_kv_transport.ml kaiju_kv_backend.ml kaiju_kv.ml
NON_LIB_MODULES=

BYTE_TARGETS=kaiju_kv.cma
NATIVE_TARGETS=kaiju_kv.cmxa

.PHONY: all test

all: native-code byte-code

test:

# Dependencies
include ../Ocamlrules.mk.in
