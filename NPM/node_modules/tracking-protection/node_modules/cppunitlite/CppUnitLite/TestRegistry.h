///////////////////////////////////////////////////////////////////////////////
//
// TESTREGISTRY.H
// 
// TestRegistry is a singleton collection of all the tests to run in a system.  
// 
///////////////////////////////////////////////////////////////////////////////

#ifndef TESTREGISTRY_H
#define TESTREGISTRY_H


class Test;
class TestResult;



class TestRegistry
{
public:
	static void addTest (Test *test);
	static void runAllTests (TestResult& result);

private:

	static TestRegistry&	instance ();
	void					add (Test *test);
	void					run (TestResult& result);

	
	Test					*tests;

};




#endif
