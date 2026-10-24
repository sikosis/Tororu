.PHONY: all clean validate

all:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean

validate:
	./scripts/validate.sh
