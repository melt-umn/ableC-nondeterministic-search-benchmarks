
APPS=$(patsubst %/,%,$(wildcard */))

all: $(APPS)

$(APPS):
	$(MAKE) -C $@

clean realclean:
	for app in $(APPS); do $(MAKE) -C $$app $@; done

.PHONY: all clean $(APPS)
.NOTPARALLEL: # Avoid running multiple Silver builds in parallel
