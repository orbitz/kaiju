CAMLP4=

OCAMLDEP_OPTS=-package core,async,zolog,konfig,kaiju_kv
OCAMLC_OPTS=$(OCAMLDEP_OPTS) -w '@f@p@u@s@40'
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

LIB_MODULES=kaiju_kv_line_transport.ml
NON_LIB_MODULES=

EXTERNAL_DEPS= \
	../konfig/konfig.cmxa \
	../konfig/konfig.cma \
	../kaiju_kv/kaiju_kv.cmxa \
	../kaiju_kv/kaiju_kv.cma

BYTE_TARGETS=kaiju_kv_line_transport.cma
NATIVE_TARGETS=kaiju_kv_line_transport.cmxa

.PHONY: all test

all: native-code byte-code

test:

# Dependencies
include ../Ocamlrules.mk.in
