NILE_RUNTIME := ../../../nile/runtimes/c
TARGET       := $(shell $(CC) -dumpmachine)
LDFLAGS      := -L.. -lgezira -L$(NILE_RUNTIME) -lnile #`freetype-config --libs`
CFLAGS       := -Wall -Werror -Wno-unused \
                -I.. -I$(NILE_RUNTIME) \
                -O3 -ffast-math \
		-I/usr/include/freetype2 \
		-I/usr/include/SDL
                #`freetype-config --cflags` \

ifneq (,$(findstring darwin,$(TARGET)))
  LDFLAGS += -framework Cocoa
else ifneq (,$(findstring mingw,$(TARGET))$(findstring cygwin,$(TARGET)))
  LDFLAGS += -lgdi32 #-mwindows
else
  LDFLAGS += -lX11 -lXext -lm -pthread -lfreetype
endif

%-demo: %-demo.c FORCE
	$(MAKE) -C $(NILE_RUNTIME) -f Makefile.gcc
	$(MAKE) -C .. -f Makefile.gcc
	$(CC) $< $(CFLAGS) $(LDFLAGS) -o $@

snow-demo:

clean:
	$(RM) -r *-demo *.dSYM *.exe

FORCE:
