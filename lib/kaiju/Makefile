CAMLP4=

OCAMLDEP_OPTS=-package core,async,zolog,konfig,kaiju_kv_memory_backend,kaiju_kv
OCAMLC_OPTS=$(OCAMLDEP_OPTS) -w '@f@p@u@s@40'
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

LIB_MODULES=
NON_LIB_MODULES=kaiju.ml

EXTERNAL_DEPS= \
	../konfig/konfig.cmxa \
	../konfig/konfig.cma \
	../kaiju_kv/kaiju_kv.cmxa \
	../kaiju_kv/kaiju_kv.cma \
	../kaiju_kv_memory_backend/kaiju_kv_memory_backend.cmxa \
	../kaiju_kv_memory_backend/kaiju_kv_memory_backend.cma

BYTE_TARGETS=kaiju.byte
NATIVE_TARGETS=kaiju.native

.PHONY: all test

all: native-code byte-code

install: all
	cp -vf kaiju.native $(PREFIX)/bin/kaiju

test:

# Dependencies
include ../Ocamlrules.mk.in
