.PHONY: build
.PHONY: test
.PHONY: sample
.PHONY: perf
.PHONY: clean

build:
	 ./node_modules/.bin/node-gyp configure && node-gyp build

test:
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f ninja test/binding.gyp
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f xcode test/binding.gyp
	ninja -C build/out/Default -f build.ninja
	./build/out/Default/test || [ $$? -eq 0 ]

sample:
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f ninja sample/binding.gyp
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f xcode sample/binding.gyp
	ninja -C build/out/Default -f build.ninja
	./build/out/Default/sample

perf:
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f ninja perf/binding.gyp
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f xcode perf/binding.gyp
	ninja -C build/out/Default -f build.ninja
	./build/out/Default/perf

clean:
	rm -Rf build
