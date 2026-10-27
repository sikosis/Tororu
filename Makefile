.PHONY: all clean validate smoke

all:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean

validate:
	./scripts/validate.sh

smoke:
	./scripts/render-smoke.sh "$(TORORU)"
