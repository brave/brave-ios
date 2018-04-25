.PHONY: build
.PHONY: build-debug
.PHONY: test
.PHONY: static
.PHONY: perf

build:
	 node-gyp configure && node-gyp build

build-debug:
	 node-gyp configure -debug && node-gyp build

test:
	 node-gyp configure -debug && node-gyp build && ./build/Debug/test

sample:
	 node-gyp configure && node-gyp build && ./build/Release/sample

perf:
	 node-gyp configure && node-gyp build && ./build/Release/perf

xcode-proj:
	node-gyp configure -- -f xcode

clean:
	node-gyp clean

