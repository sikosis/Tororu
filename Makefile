.PHONY: all clean test validate smoke

CXX ?= c++

all:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean

test:
	$(CXX) -std=c++17 -Wall -Wextra -Isrc \
		tests/MarkdownTest.cpp src/Markdown.cpp -o tests/markdown_test
	./tests/markdown_test

validate: test
	./scripts/validate.sh

smoke:
	./scripts/render-smoke.sh "$(TORORU)"
