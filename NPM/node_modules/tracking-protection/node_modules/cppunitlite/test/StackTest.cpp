#include "CppUnitLite/TestHarness.h"
#include "Stack.h"

#include <string>


SimpleString StringFrom(const std::string& value)
{
	return SimpleString(value.c_str());
}



TEST( Stack, creation )
{
  Stack s;
  LONGS_EQUAL(0, s.size());
  std::string b = "asa";
  CHECK_EQUAL("asa", b);
}
