#-*-mode:makefile-gmake;indent-tabs-mode:t;tab-width:8;coding:utf-8-*-┐
#───vi: set et ft=make ts=8 tw=8 fenc=utf-8 :vi───────────────────────┘
#
# SYNOPSIS
#
#   GNU-style Makefile for GNU/Systemd &c.
#
# DESCRIPTION
#
#   We recommend just running the scripts directly, e.g.
#
#     ./derasterize.c -h
#
#   The above approach is most likely to work and will most likely go
#   faster too, especially if Clang is installed. Another good option is
#   to run the prebuilt one-size-fits-all binaries we've included:
#
#     bin/derasterize.com -h
#
#   This makefile is mostly only included to conform to the generally
#   accepted conventions. Since we're doing that, we've included more
#   goodies too, e.g. samples, checks, determinism, explainability.

.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY:	all					\
	bins					\
	check					\
	clean					\
	samples					\
	assemblies				\
	maintainer-clean

all:	check					\
	bins					\
	samples					\
	assemblies

MAKEFLAGS +=					\
	--no-builtin-rules

BINS =	o/$(MODE)/derasterize.bin		\
	o/$(MODE)/basicidea.bin

CHECKS =					\
	o/$(MODE)/derasterize.check

LDLIBS =					\
	-lm

TARGET_ARCH =					\
	-march=native

CFLAGS =					\
	-g					\
	-Ofast					\
	-mstringop-strategy=vector_loop		\
	-fdebug-prefix-map="$(PWD)"=		\
	$(NOMAGIC_CFLAGS)

CPPFLAGS =					\
	-Wno-builtin-macro-redefined		\
	-D__DATE__="redacted"			\
	-D__TIMESTAMP__="redacted"		\
	-D__TIME__="redacted"

LDFLAGS =					\
	-Wl,--cref				\
	-Wl,-Map=$@.map				\
	-Wl,--build-id=none			\
	$(NOMAGIC_LDFLAGS)

ASFLAGS =					\
	-Wa,-amghls=$@.lst

NOMAGIC_CFLAGS =				\
	-fno-pie				\
	-mno-red-zone				\
	-fno-unwind-tables			\
	-fno-dwarf2-cfi-asm			\
	-fno-stack-protector			\
	-fno-omit-frame-pointer			\
	-fno-optimize-sibling-calls		\
	-fno-semantic-interposition		\
	-fno-optimize-sibling-calls		\
	-fno-asynchronous-unwind-tables		\

NOMAGIC_LDFLAGS =				\
	-static					\
	-no-pie					\

ARTIFACTS =					\
	$(OBJS)					\
	$(BINS)					\
	$(ASSEMBLIES)

################################################################################

FILES := $(wildcard *.* samples/*.*)
SRCS_C = $(filter %.c,$(FILES))
OBJS_C = $(SRCS_C:%.c=o/$(MODE)/%.o)
SRCS = $(SRCS_C)
OBJS = $(OBJS_C)
ASSEMBLIES = $(SRCS_C:%.c=o/$(MODE)/%.s)
SAMPLES_JPG = $(filter samples/%.jpg,$(FILES))
SAMPLES_PNG = $(filter samples/%.png,$(FILES))
SAMPLES_UAART = $(SAMPLES_JPG:%=%.uaart) $(SAMPLES_PNG:%=%.uaart)
SAMPLES = $(SAMPLES_UAART)

bins: $(BINS)
check: $(CHECKS)
samples: $(SAMPLES)
listings: $(LISTINGS)
assemblies: $(ASSEMBLIES)

clean:
	$(RM) $(ARTIFACTS)

maintainer-clean: clean
	$(RM) $(SAMPLES_UAART)

o/$(MODE)/%.o: %.c
	@mkdir -p $(dir $@)
	$(COMPILE.c) $(ASFLAGS) $(OUTPUT_OPTION) $<

o/$(MODE)/%.s: %.c
	@mkdir -p $(dir $@)
	$(COMPILE.c) -S -g0 $(OUTPUT_OPTION) $<

o/$(MODE)/%.bin: o/$(MODE)/%.o
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@

%.uaart: % o/$(MODE)/derasterize.bin
	o/$(MODE)/derasterize.bin -y20 -x70 $< >$@

################################################################################

$(OBJS): Makefile

o/$(MODE)/basicidea.bin: o/$(MODE)/basicidea.o
o/$(MODE)/derasterize.bin: o/$(MODE)/derasterize.o

o/$(MODE)/derasterize.check:			\
		o/$(MODE)/derasterize.bin	\
		samples/snake.jpg		\
		bin/tally.sh
	o/$(MODE)/derasterize.bin -y12 -x30 samples/snake.jpg | bin/tally.sh
	@touch $@
