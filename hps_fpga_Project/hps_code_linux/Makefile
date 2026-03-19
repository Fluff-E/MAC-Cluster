TARGET ?= linux_cluster

# Native build defaults for compiling directly on the Linux SoC.
CC ?= gcc
ALT_DEVICE_FAMILY ?= soc_cv_av
HWLIBS_INCLUDE_DIR ?= /usr/include
ALT_FAMILY_INCLUDE_DIR ?= /usr/include/$(ALT_DEVICE_FAMILY)

CFLAGS ?= -O2 -g -Wall -D$(ALT_DEVICE_FAMILY) -I$(ALT_FAMILY_INCLUDE_DIR) -I$(HWLIBS_INCLUDE_DIR)
LDFLAGS ?= -g -Wall

SOURCES := main.c
OBJECTS := $(SOURCES:.c=.o)

.PHONY: all build clean print-vars

all: build
build: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

print-vars:
	@echo "CC=$(CC)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "LDFLAGS=$(LDFLAGS)"
	@echo "HWLIBS_INCLUDE_DIR=$(HWLIBS_INCLUDE_DIR)"
	@echo "ALT_FAMILY_INCLUDE_DIR=$(ALT_FAMILY_INCLUDE_DIR)"

clean:
	rm -f $(TARGET) $(OBJECTS) *.a *~
