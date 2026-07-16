ERL_ROOT := $(shell erl -noshell -eval 'io:format("~s", [code:root_dir()]), halt().')
ERL_INCLUDE := $(ERL_ROOT)/usr/include
SOURCE := native/managed_reference_spike.c
TARGET := priv/managed_reference_spike.so
CC ?= cc
CFLAGS ?= -O2
CFLAGS += -std=c11 -fPIC -Wall -Wextra -Werror -I$(ERL_INCLUDE) $(EXTRA_CFLAGS)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  LDFLAGS := -dynamiclib -undefined dynamic_lookup
else
  LDFLAGS := -shared
endif
LDFLAGS += $(EXTRA_LDFLAGS)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCE)
	@mkdir -p priv
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)
