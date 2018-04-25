{
  "targets": [{
    "target_name": "bloom-filter-cpp",
    "sources": [
      "addon.cpp",
      "BloomFilterWrap.cpp",
      "BloomFilterWrap.h",
      "BloomFilter.cpp",
      "BloomFilter.h",
      "hashFn.cpp",
    ],
    "include_dirs": [
      ".",
    ],
    "conditions": [
      ['OS=="win"', {
        }, {
          'cflags_cc': [ '-fexceptions' ]
        }
      ]
    ],
    "xcode_settings": {
      "OTHER_CFLAGS": [ "-ObjC" ],
      "OTHER_CPLUSPLUSFLAGS" : ["-std=c++11","-stdlib=libc++", "-v"],
      "MACOSX_DEPLOYMENT_TARGET": "10.9",
      "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
    },
  }]
}
