{
  "targets": [{
    "target_name": "test",
    "type": "executable",
    "sources": [
      "../test/test-main.cpp",
      "../test/hashset-test.cpp",
      "../test/exampleData.h",
      "../HashSet.cpp",
      "../HashSet.h",
    ],
    "include_dirs": [
      "..",
      '../node_modules/cppunitlite',
      '../node_modules/nan'
    ],
    "dependencies": [
      "../node_modules/cppunitlite/binding.gyp:CppUnitLite",
    ],
    "conditions": [
      ['OS=="win"', {
        }, {
          'cflags_cc': [ '-fexceptions' ]
        }
      ],
      ['OS=="linux"', {
        "defines": ["DISABLE_REGEX"],
      }, {
      }]
    ],
    "xcode_settings": {
      "OTHER_CFLAGS": [ "-ObjC" ],
      "OTHER_CPLUSPLUSFLAGS" : ["-std=c++11","-stdlib=libc++", "-v"],
      "OTHER_LDFLAGS": ["-stdlib=libc++"],
      "MACOSX_DEPLOYMENT_TARGET": "10.9",
      "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
    },
  }]
}
