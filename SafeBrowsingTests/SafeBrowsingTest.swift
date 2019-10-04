// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import XCTest
import CoreData
@testable import Client

class SafeBrowsingTest: XCTestCase {
    
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    func testCanonicalizeURL() {
        //TODO:
    }
    
    func testBackoffTimeCalculation() {
        var randoms = [
            0.6046602879796196,
            0.9405090880450124,
            0.6645600532184904,
            0.4377141871869802,
            0.4246374970712657,
            0.6868230728671094,
            0.06563701921747622,
            0.15651925473279124,
            0.09696951891448456,
            0.30091186058528707
        ]
        
        var expected = [
            1444,
            1746,
            1498,
            1293,
            1282,
            1518,
            959,
            1040,
            987,
            1170
        ]
        
        for i in 0..<randoms.count {
            XCTAssertTrue(Int(calculateBackoffTime(0, randomValue: randoms[i])) == expected[i])
        }
        
        randoms = [
            0.6046602879796196,
            0.9405090880450124,
            0.6645600532184904,
            0.4377141871869802,
            0.4246374970712657,
            0.6868230728671094,
            0.06563701921747622,
            0.15651925473279124,
            0.09696951891448456,
            0.30091186058528707
        ]
        
        expected = [
            11553,
            13971,
            11984,
            10351,
            10257,
            12145,
            7672,
            8326,
            7898,
            9366
        ]
        
        for i in 0..<randoms.count {
            XCTAssertTrue(Int(calculateBackoffTime(3, randomValue: randoms[i])) == expected[i])
        }
    }
    
    //MIN((2N-1 * 15 minutes) * (RAND + 1), 24 hours)
    private func calculateBackoffTime(_ numberOfRetries: Int16, randomValue: Double) -> Double {
        let minutes = Double(1 << Int(numberOfRetries)) * (15.0 * (randomValue + 1))
        return minutes * 60
    }
}

/** Calculate Backoff time values are taken from Google's Safe-Browsing Go-Lang implementation! **/
/** After stripping the code we get (which can be used to verify our algorithm is correct):
 
 package main
 
 import (
     "fmt"
     "math/rand"
     "time"
 )
 
 const (
     maxRetryDelay  = 24 * time.Hour
     baseRetryDelay = 15 * time.Minute
     jitter         = 30 * time.Second
 )
 
 func main() {
     retries := 3
     n := 1 << uint(retries)
 
     for i := 1;  i<= 10; i++ {
         rnd := rand.Float64()
         delay := time.Duration(float64(n) * (rnd + 1) * float64(baseRetryDelay))
         if delay > maxRetryDelay {
             delay = maxRetryDelay
         }
 
         fmt.Println("%f", rnd)
         fmt.Println("%ld", int64(delay / time.Second))
     }
 }
 **/
