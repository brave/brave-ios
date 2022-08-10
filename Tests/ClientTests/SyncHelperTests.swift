import Foundation
import XCTest

@testable import Brave

class SyncHelperTests: XCTestCase {
  
  func testSyncedSessionPeriodDate() {
    var dateComponents = DateComponents()
    dateComponents.year = 1980
    dateComponents.month = 7
    dateComponents.day = 11
    dateComponents.hour = 8
    dateComponents.minute = 34

    let userCalendar = Calendar(identifier: .gregorian)
    
    let today = Date()
    let yesterday = userCalendar.date(byAdding: .day, value: -1, to: today)!
    let randomDateInLastWeek = userCalendar.date(byAdding: .day, value: -Int.random(in: 2 ... 5), to: today)!
    let randomDateInLastMonth = userCalendar.date(byAdding: .day, value: -Int.random(in: 10 ... 14), to: today)!
    let someRandomDateTime = userCalendar.date(from: dateComponents)!
    
    
    XCTAssertTrue(someRandomDateTime.formattedSyncSessionPeriodDate == "Last synced: 08:34 AM 07-11-1980")
    XCTAssertTrue(today.formattedActivePeriodDate == "Active Today")
    XCTAssertTrue(yesterday.formattedActivePeriodDate == "Active Yesterday")
    XCTAssertTrue(randomDateInLastWeek.formattedActivePeriodDate == "Active Last Week")
    XCTAssertTrue(randomDateInLastMonth.formattedActivePeriodDate == "Active Last Month")
  }
}
