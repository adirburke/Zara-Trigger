import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Zara_TriggerTests.allTests),
    ]
}
#endif
