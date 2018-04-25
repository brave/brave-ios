{
  "targets": [{
    "target_name": "tracking-protection",
    "type": "static_library",
    "sources": [
      "TPParser.cpp",
      "TPParser.h",
      "TrackerData.h",
      "FirstPartyHost.h",
    ],
    "include_dirs": [
      ".",
      './node_modules/hashset-cpp'
    ],
    "dependencies": [
      "./node_modules/hashset-cpp/binding.gyp:hashset-cpp"
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
  },
  {
      "target_name": "tp_node_addon",
      "sources": [
        "TPParser.cpp",
        "TPParser.h",
        "TrackerData.h",
        "FirstPartyHost.h",
        "./node_addon/TPParserWrap.h",
        "./node_addon/TPParserWrap.cpp",
        "./node_addon/addon.cpp"
      ],
      "include_dirs": [
        ".",
        './node_modules/hashset-cpp'
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
      "OTHER_LDFLAGS": ["-stdlib=libc++"],
      "MACOSX_DEPLOYMENT_TARGET": "10.9",
      "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
      },
     },
   {
    "target_name": "sample",
    "type": "executable",
    "sources": [
      "main.cpp",
      "TPParser.cpp",
      "TPParser.h",
      "TrackerData.h",
      "FirstPartyHost.h",
      "./node_modules/hashset-cpp/HashSet.cpp",
      "./node_modules/hashset-cpp/HashSet.h",
      "./node_modules/hashset-cpp/HashFn.h"
    ],
    "include_dirs": [
      ".",
      './node_modules/hashset-cpp'
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
      "OTHER_LDFLAGS": ["-stdlib=libc++"],
      "MACOSX_DEPLOYMENT_TARGET": "10.9",
      "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
    },
  }, {
    "target_name": "test",
    "type": "executable",
    "sources": [
      "./test/test-main.cpp",
      "./test/tracking-protection-test.cpp",
      "TPParser.cpp",
      "TPParser.h",
      "TrackerData.h",
      "FirstPartyHost.h",
      "./node_modules/hashset-cpp/HashSet.cpp",
      "./node_modules/hashset-cpp/HashSet.h",
      "./node_modules/hashset-cpp/HashFn.h"
    ],
    "include_dirs": [
      ".",
      "<!(node -e \"require('cppunitlite')\")",
      "<!(node -e \"require('nan')\")",
      './node_modules/hashset-cpp'
    ],
    "dependencies": [
      "./node_modules/cppunitlite/binding.gyp:CppUnitLite"
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
