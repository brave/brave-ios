{
  'targets': [
    {
      # unit testing library
      'target_name': 'CppUnitLite',
      'type': 'static_library',
      'sources': [
         'src/Failure.cpp',
         'src/SimpleString.cpp',
         'src/Test.cpp',
         'src/TestResult.cpp',
         'src/TestRegistry.cpp'
      ],
      'include_dirs': [
         './CppUnitLite'
      ]
    },
    {
      'target_name': 'test',
      'type': 'executable',
      'dependencies': [
        'CppUnitLite'
      ],
      'sources': [
        'test/StackMain.cpp',
        'test/StackTest.cpp',
      ],
      'include_dirs': [
         '.'
      ]
    },
  ]
}