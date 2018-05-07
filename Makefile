
APPS=$(wildcard */)

all: $(APPS)

$(APPS):
	$(MAKE) -C $@

clean:
	for app in $(APPS); do $(MAKE) -C $$app clean; done

.PHONY: all clean $(APPS)
.NOTPARALLEL: # Avoid running multiple Silver builds in parallel
