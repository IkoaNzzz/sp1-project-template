ARCH_LIBDIR ?= /lib/$(shell $(CC) -dumpmachine)
SELF_EXE = target/release/fibonacci

.PHONY: all
all: $(SELF_EXE) sp1.manifest
ifeq ($(SGX),1)
all: sp1.manifest.sgx sp1.sig
endif

ifeq ($(DEBUG),1)
GRAMINE_LOG_LEVEL = debug
else
GRAMINE_LOG_LEVEL = error
endif

sp1.manifest: sp1.manifest.template
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dself_exe=$(SELF_EXE) \
		-Duser_path=$(HOME) \
		$< $@

# Make on Ubuntu <= 20.04 doesn't support "Rules with Grouped Targets" (`&:`),
# see the helloworld example for details on this workaround.
sp1.manifest.sgx sp1.sig: sgx_sign
	@:

.INTERMEDIATE: sgx_sign
sgx_sign: sp1.manifest $(SELF_EXE)
	gramine-sgx-sign \
		--manifest $< \
		--output $<.sgx

ifeq ($(SGX),)
GRAMINE = gramine-direct
else
GRAMINE = gramine-sgx
endif

.PHONY: start-sp1
start-sp1: all
	$(GRAMINE) sp1 --prove

.PHONY: clean
clean:
	$(RM) -rf *.sig *.manifest.sgx *.manifest result-* OUTPUT

.PHONY: distclean
distclean: clean
	$(RM) -rf target/
