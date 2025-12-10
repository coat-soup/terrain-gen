class_name TestExampleTestable
extends GdUnitTestSuite

func test_example():
	var cs = preload("res://test/example_testable.cs").new()
	assert(cs.add_numbers(2,7) == 9)
	cs.free()

func test_standalone():
	assert([1,2,3].size() == 3)
