SUBDIRS = konfig kaiju_kv kaiju kaiju_kv_memory_backend kaiju_kv_line_transport kaiju_kv_scow_backend

all_apps = $(SUBDIRS)

subdirs_clean = $(all_apps:%=%_clean)

subdirs_test  = $(all_apps:%=%_test)

subdirs_install = $(all_apps:%=%_install)

.PHONY: all test clean $(SUBDIRS) $(subdirs_clean) $(subdirs_test) $(subdirs_install)

all: $(SUBDIRS)

install: $(subdirs_install)

test: $(subdirs_test)

clean: $(subdirs_clean)

kaiju: konfig kaiju_kv

kaiju: kaiju_kv_line_transport

kaiju: kaiju_kv_memory_backend kaiju_kv_scow_backend

kaiju_kv: konfig

kaiju_kv_memory_backend: kaiju_kv

kaiju_kv_line_transport: kaiju_kv

kaiju_kv_scow_backend: kaiju_kv_memory_backend kaiju_kv

$(SUBDIRS):
	$(MAKE) -C $@ .d
	$(MAKE) -C $@

$(subdirs_install):
	$(MAKE) -C $(patsubst %_install,%,$@) install

$(subdirs_test):
	$(MAKE) -C $(patsubst %_test,%,$@) test

$(subdirs_clean):
	$(MAKE) -C $(patsubst %_clean,%,$@) clean

