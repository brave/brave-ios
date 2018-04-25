{
  "targets": [{
    "target_name": "test",
    "type": "executable",
    "sources": [
      "../test/test_main.cc",
      "../test/parser_test.cc",
      "../test/options_test.cc",
      "../test/rule_types_test.cc",
      "../test/cosmetic_filter_test.cc",
      "../test/util.cc",
      "../ad_block_client.cc",
      "../ad_block_client.h",
      "../cosmetic_filter.cc",
      "../cosmetic_filter.h",
      "../filter.cc",
      "../filter.h",
      "../node_modules/bloom-filter-cpp/BloomFilter.cpp",
      "../node_modules/bloom-filter-cpp/BloomFilter.h",
      "../node_modules/bloom-filter-cpp/hashFn.cpp",
      "../node_modules/bloom-filter-cpp/hashFn.h",
      "../node_modules/hashset-cpp/HashSet.cpp",
      "../node_modules/hashset-cpp/HashSet.h"
    ],
    "include_dirs": [
      "..",
      '../node_modules/bloom-filter-cpp',
      '../node_modules/hashset-cpp',
      '../node_modules/cppunitlite',
      '../node_modules/nan'
      "..",
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
      ['OS!="linux"', {
        "defines": ["ENABLE_REGEX"],
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
    "cflags": [
      "-std=c++11"
    ]
  }]
}
