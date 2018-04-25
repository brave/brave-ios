# CppUnitLite - lite c++ testing framework

This is a modified version of CppUnitLite

## Usage

Use CppUnitLite to add unit tests to the c++ side of a node addon.

### Installing

Install cppunitlite with npm.  It has no package dependencies, but
requires node-gyp to be installed and working.

    $ npm i --save-dev cppunitlite
    npm http GET https://registry.npmjs.org/cppunitlite
    npm http 304 https://registry.npmjs.org/cppunitlite

    > cppunitlite@0.0.3 install Z:\code\node_modules\cppunitlite
    > node-gyp rebuild

    ... platform dependent stuff ...
    cppunitlite@0.0.3 node_modules\cppunitlite

### Changes to your binding.gyp

Add a test target to your binding.gyp:

    {
      'target_name': 'test',
      'type': 'executable',
      'sources': [
        # your test files
      ]
      'include_dirs': [
        # your project include files
        '<!(node -e "require(\'cpppunitlite\')'
      ]
      'dependencies': [
        'node_modules/cppunitlite/binding.gyp:CppUnitLite'
      ]
    }

### A test main

CppUnitLite does not provide a main() function, but it's easy to write
a minimal one; for example:

    #include "CppUnitLite/TestHarness.h"

    int main()
    {
        TestResult tr;
        TestRegistry::runAllTests(tr);

        return 0;
    }

### Write Unit Tests

The include directories are set up so that the CppUnitLite headers
should be included with a path.

    #include "CppUnitLite/TestHarness.h"

    #include <string>

    static inline SimpleString StringFrom(const std::string& value)
    {
    	return SimpleString(value.c_str());
    }

    TEST( Hello, world )
    {
      std::string s1("Hello"), s2("Hello"), s3("world");

      CHECK_EQUAL(s1, s2);
      CHECK_EQUAL(s2, s1);

      CHECK(s1 != s3);
    }

## Version history

Original version from Michael Feathers
http://www.objectmentor.com/resources/downloads.html
http://www.objectmentor.com/resources/bin/CppUnitLite.zip

Some documentation here:
http://c2.com/cgi/wiki?CppUnitLite

Modified version by Keith Bauer, published as an SVN repository
http://www.onesadcookie.com/svn/CppUnitLite

Imported to git 2014-01-19 and pushed to github
