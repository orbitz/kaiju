CAMLP4=

CORE_PACKAGES=core,async
SCOW_PACKAGES=scow,scow_transport_stream,scow_transport_stream_codec_json,kaiju_kv_memory_backend
PACKAGES=$(CORE_PACKAGES),zolog,konfig,kaiju_kv,$(SCOW_PACKAGES),comparelib.syntax,json-wheel

OCAMLDEP_OPTS=-package $(PACKAGES) -syntax camlp4o
OCAMLC_OPTS=$(OCAMLDEP_OPTS) -w '@f@p@u@s@40'
OCAMLOPT_OPTS=$(OCAMLC_OPTS)

LIB_MODULES=kaiju_kv_scow_backend.ml
NON_LIB_MODULES=

EXTERNAL_DEPS= \
	../konfig/konfig.cmxa \
	../konfig/konfig.cma \
	../kaiju_kv/kaiju_kv.cmxa \
	../kaiju_kv/kaiju_kv.cma

BYTE_TARGETS=kaiju_kv_scow_backend.cma
NATIVE_TARGETS=kaiju_kv_scow_backend.cmxa

.PHONY: all test

all: native-code byte-code

test:

# Dependencies
include ../Ocamlrules.mk.in
