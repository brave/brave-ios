.PHONY: build
.PHONY: test
.PHONY: sample

build:
	 ./node_modules/.bin/node-gyp rebuild

test:
	cd test
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f ninja test/binding.gyp
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f xcode test/binding.gyp
	ninja -C ./build/out/Default -f build.ninja
	./build/out/Default/test || [ $$? -eq 0 ]

sample:
	cd sample
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f ninja sample/binding.gyp
	./node_modules/node-gyp/gyp/gyp_main.py --generator-output=./build --depth=. -f xcode sample/binding.gyp
	ninja -C ./build/out/Default -f build.ninja
	./build/out/Default/sample

clean:
	rm -Rf build
