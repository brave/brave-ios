[![Build Status](https://travis-ci.org/bbondy/bloom-filter-cpp.svg?branch=master)](https://travis-ci.org/bbondy/bloom-filter-cpp)

# BloomFilter.cpp
C++ Native node module Bloom filter written in C++ for use in node or any other C++ project.

The Bloom filter tests whether an element belongs to a set. False positive matches are possible but not common, false negatives are not possible.
The Bloom filter library also implements Rabin–Karp algorithm with Rabin fingerprint hashes for multiple substring searches.

This is a port of a [similar lib](https://github.com/bbondy/bloom-filter-js) I prototyped in JS.

## To include bloom-filter-cpp in your project:

```
npm install --save bloom-filter-cpp
```


## JS Usage

```javascript
var BloomFilter = require('bloom-filter-cpp').BloomFilter

var b1 = new BloomFilter()

console.log('b1 ading hello')
b1.add('hello')

console.log('b1 exists hello? ', b1.exists('hello'))
console.log('b1 exists hello2? ', b1.exists('hello2'))

var b2 = new BloomFilter()
console.log('b2 exists hello? ', b2.exists('hello'))
console.log('b2 exists hello2? ', b2.exists('hello2'))
```


## C++ Usage

```c++
#include "BloomFilter.h"
#include <iostream>

using namespace std;

int main(int argc, char**argv) {
  BloomFilter b;
  b.add("Brian");
  b.add("Ronald");
  b.add("Bondy");

  // Prints true
  cout << (b.exists("Brian") ? "true" : "false") << endl;

  // Prints false
  cout << (b.exists("Brian Ronald") ? "true" : "false") << endl;

  // Create a new BloomerFilter form a previous serialization
  BloomFilter b2(b.getBuffer(), b.getByteBufferSize());

  // Prints the same as above
  cout << (b2.exists("Brian") ? "true" : "false") << endl;
  cout << (b2.exists("Brian Ronald") ? "true" : "false") << endl;

  // And you can check if any substring of a passed string exists
  // Prints true
  cout << (b.substringExists("Hello my name is Brian", 5) ? "true" : "false") << endl;
  // Prints false
  cout << (b.substringExists("Hello my name is Bri", 3) ? "true" : "false") << endl;

  return 0;
}
```


## Developing bloom-filter-cpp

````
git clone bloom-filter-cpp
npm install
```

## Build everything in release

```
make
```

## Running sample

```
make sample
```

## Running tests

```
make test
```

## Clearing build files
```
make clean
```
