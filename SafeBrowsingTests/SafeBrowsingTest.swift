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

    //WKWebView automatically canonicalized URLs for us anyway.. and this is our hashPrefixes and everything works..
    //So not sure if we even need a canonicalization test tbh..
    func testCanonicalizeURL() {
        let expectedCanonicalURLs = [
            "https://testsafebrowsing.appspot.com/s/phishing.html": "https://testsafebrowsing.appspot.com/s/phishing.html",
            "https://testsafebrowsing.appspot.com/s/malware.html": "https://testsafebrowsing.appspot.com/s/malware.html",
            "https://testsafebrowsing.appspot.com/s/malware_in_iframe.html": "https://testsafebrowsing.appspot.com/s/malware_in_iframe.html",
            "https://testsafebrowsing.appspot.com/s/unwanted.html": "https://testsafebrowsing.appspot.com/s/unwanted.html",
            "https://testsafebrowsing.appspot.com/s/image_small.html": "https://testsafebrowsing.appspot.com/s/image_small.html",
            "https://testsafebrowsing.appspot.com/s/image_medium.html": "https://testsafebrowsing.appspot.com/s/image_medium.html",
            "https://testsafebrowsing.appspot.com/s/image_large.html": "https://testsafebrowsing.appspot.com/s/image_large.html",
            "https://testsafebrowsing.appspot.com/s/bad_css.html": "https://testsafebrowsing.appspot.com/s/bad_css.html",
            "https://testsafebrowsing.appspot.com/s/bad_javascript.html": "https://testsafebrowsing.appspot.com/s/bad_javascript.html",
            "https://testsafebrowsing.appspot.com/s/trick_to_bill.html": "https://testsafebrowsing.appspot.com/s/trick_to_bill.html",
            "https://testsafebrowsing.appspot.com/s/content.exe": "https://testsafebrowsing.appspot.com/s/content.exe",
            "https://testsafebrowsing.appspot.com/s/badrep.exe": "https://testsafebrowsing.appspot.com/s/badrep.exe",
            "https://testsafebrowsing.appspot.com/s/unknown.exe": "https://testsafebrowsing.appspot.com/s/unknown.exe",
            "https://testsafebrowsing.appspot.com/s/pua.exe": "https://testsafebrowsing.appspot.com/s/pua.exe",
            "https://testsafebrowsing.appspot.com/apiv4/IOS/MALWARE/URL/": "https://testsafebrowsing.appspot.com/apiv4/IOS/MALWARE/URL/",
            "https://testsafebrowsing.appspot.com/apiv4/IOS/SOCIAL_ENGINEERING/URL/": "https://testsafebrowsing.appspot.com/apiv4/IOS/SOCIAL_ENGINEERING/URL/",
            "https://testsafebrowsing.appspot.com/apiv4/OSX/MALWARE/URL/": "https://testsafebrowsing.appspot.com/apiv4/OSX/MALWARE/URL/",
            "https://testsafebrowsing.appspot.com/apiv4/OSX/SOCIAL_ENGINEERING/URL/": "https://testsafebrowsing.appspot.com/apiv4/OSX/SOCIAL_ENGINEERING/URL/",
            "https://testsafebrowsing.appspot.com/s/notif_pageload.html": "https://testsafebrowsing.appspot.com/s/notif_pageload.html",
            "https://testsafebrowsing.appspot.com/s/geoloc_click.html": "https://testsafebrowsing.appspot.com/s/geoloc_click.html",
            "https://testsafebrowsing.appspot.com/s/notif_geoloc_delay.html": "https://testsafebrowsing.appspot.com/s/notif_geoloc_delay.html",
            "https://testsafebrowsing.appspot.com/s/media_batch.html": "https://testsafebrowsing.appspot.com/s/media_batch.html",
            "https://testsafebrowsing.appspot.com/s/midi_click.html": "https://testsafebrowsing.appspot.com/s/midi_click.html",
            "https://testsafebrowsing.appspot.com/s/bad_login.html": "https://testsafebrowsing.appspot.com/s/bad_login.html",
            "https://testsafebrowsing.appspot.com/s/low_rep_login.html": "https://testsafebrowsing.appspot.com/s/low_rep_login.html",
            
            "http://host/%25%32%35": "http://host/%25",
            "http://host/%25%32%35%25%32%35": "http://host/%25%25",
            "http://host/%2525252525252525": "http://host/%25",
            "http://host/asdf%25%32%35asd": "http://host/asdf%25asd",
            "http://host/%%%25%32%35asd%%": "http://host/%25%25%25asd%25%25",
            "http://www.google.com/": "http://www.google.com/",
            "http://%31%36%38%2e%31%38%38%2e%39%39%2e%32%36/%2E%73%65%63%75%72%65/%77%77%77%2E%65%62%61%79%2E%63%6F%6D/": "http://168.188.99.26/.secure/www.ebay.com/",
            "http://195.127.0.11/uploads/%20%20%20%20/.verify/.eBaysecure=updateuserdataxplimnbqmn-xplmvalidateinfoswqpcmlx=hgplmcx/": "http://195.127.0.11/uploads/%20%20%20%20/.verify/.eBaysecure=updateuserdataxplimnbqmn-xplmvalidateinfoswqpcmlx=hgplmcx/",
            "http://host%23.com/%257Ea%2521b%2540c%2523d%2524e%25f%255E00%252611%252A22%252833%252944_55%252B": "http://host%23.com/~a!b@c%23d$e%25f^00&11*22(33: ",
            "http://3279880203/blah": "http://195.127.0.11/blah",
            "http://www.google.com/blah/..": "http://www.google.com/",
            "www.google.com/": "http://www.google.com/",
            "www.google.com": "http://www.google.com/",
            "http://www.evil.com/blah#frag": "http://www.evil.com/blah",
            "http://www.GOOgle.com/": "http://www.google.com/",
            "http://www.google.com.../": "http://www.google.com/",
            "http://www.google.com/foo\tbar\rbaz\n2": "http://www.google.com/foobarbaz2",
            "http://www.google.com/q?": "http://www.google.com/q?",
            "http://www.google.com/q?r?": "http://www.google.com/q?r?",
            "http://www.google.com/q?r?s": "http://www.google.com/q?r?s",
            "http://evil.com/foo#bar#baz": "http://evil.com/foo",
            "http://evil.com/foo;": "http://evil.com/foo;",
            "http://evil.com/foo?bar;": "http://evil.com/foo?bar;",
            "http://\u{01}\u{80}.com/": "http://%01%80.com/",
            "http://notrailingslash.com": "http://notrailingslash.com/",
            "http://www.gotaport.com:1234/": "http://www.gotaport.com/",
            "  http://www.google.com/  ": "http://www.google.com/",
            "http:// leadingspace.com/": "http://%20leadingspace.com/",
            "http://%20leadingspace.com/": "http://%20leadingspace.com/",
            "%20leadingspace.com/": "http://%20leadingspace.com/",
            "https://www.securesite.com/": "https://www.securesite.com/",
            "http://host.com/ab%23cd": "http://host.com/ab%23cd",
            "http://host.com//twoslashes?more//slashes": "http://host.com/twoslashes?more//slashes"
        ]
        
        for (key, value) in expectedCanonicalURLs {
            if let url = URL(string: key), let expectedURL = URL(string: value) {
                if SafeBrowsing.canonicalize(url: url).absoluteString != expectedURL.absoluteString {
                    XCTFail("Failed to canonicalize URL: \(key) -- Result: \(SafeBrowsing.canonicalize(url: url).absoluteString) -- Expected: \(expectedURL.absoluteString)")
                }
            }
        }
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
    
    func testURLHashes() {
        let expectedHashes: [String: [String]] = [
            "https://testsafebrowsing.appspot.com/s/phishing.html": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "771MOrRPMn6xPKlCrXx/CrR+wmCk0LgFFoSgGy7zUiA=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "fYlbhlaZKG9iZg0Uu2J6FCYMbDypo5WZItm2XEPyCZ0="
            ],

            "https://testsafebrowsing.appspot.com/s/malware.html": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "WwuJdQx48jP+4lxr4y2Sj82AWoxUVcIRDSk1PC9Rf+4=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "ughP1VMfIPT95GVn69Enm60bIwqreH8lvw8A01aP4oY="
            ],

            "https://testsafebrowsing.appspot.com/s/malware_in_iframe.html": [    "XQr5rZlaxa06obhOy0/4fcldMidOETxXNxGOoGWb0uQ=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "OWiRf/JG0Z9zGDlHzRk/nnTnxPOHwvbTO/tusbj8F2I=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE="
            ],

            "https://testsafebrowsing.appspot.com/s/unwanted.html": [    "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "saPJX9ZJXt62tIL6gn5dwL6wU5H0P+dSKfNu/YS1ZlA=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "L/Ta7yF/1AAX1+q8UGAp5z4S65QJyYYm2cbyCvRmzEs=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E="
            ],

            "https://testsafebrowsing.appspot.com/s/image_small.html": [    "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "g5qm7VEL7iMEUXQfzcmINqHhEgSlfzClkZLqfLo7LWs=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "6alqJ/eYsnu6GN+49+QI6LclcrcY4KWr/w9BTrJ+GoA="
            ],

            "https://testsafebrowsing.appspot.com/s/image_medium.html": [    "Rsj73U7+KW6qAtzbZ4P3zPxTL0aIjIj8Q5Q17fWe7a4=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "FB7hHiROwtDJDuVncarsOz2Mj5jZjpoWmkQQ7K8439A=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY="
            ],

            "https://testsafebrowsing.appspot.com/s/image_large.html": [    "PxJC1lupJN/hEFoYImIrkUmDtlt+TVsQfo/nkIN3Pcs=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "HNyFQBWGEFN+Z8+CmksasDxK2dGInWdRY3Z369cLv7c=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY="
            ],

            "https://testsafebrowsing.appspot.com/s/bad_css.html": [    "Copafgd6zzUglpli6c5Ud1TYE8ozVtxE+IsaBcdSjgA=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "yYgdlkerPueb+3/303W9uIh+Yv4yoZbXaYQDqnCa3gI=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY="
            ],

            "https://testsafebrowsing.appspot.com/s/bad_javascript.html": [    "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "7mLBWc8iCsRNRppNwzYeWGg2HuduMvphBhZppkT2HpQ=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "gBF5a26C0WXgWiDP0lySFS5tj1EzmNyQ+7/BuV+NNI0=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E="
            ],

            "https://testsafebrowsing.appspot.com/s/trick_to_bill.html": [    "TkWTMqVbKw8MgYU6JPMBLLlhLhNfXPllDLk5VcwLCeM=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "piBzYLCw9mlBE+RxeT1NzodrEthKiViY/NpR6jwOtmA=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY="
            ],

            "https://testsafebrowsing.appspot.com/s/content.exe": [    "NMQNJvW9HDvmN9HEB37GtqX0s41/KCeLFGPlsviUlBA=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "roFrqSmTwf4t6NOFhXlY2xA6N7tJD8EITc0HL/8GcJE=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY="
            ],

            "https://testsafebrowsing.appspot.com/s/badrep.exe": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "F9W7e4SkEE1lyxvigpLPwDZYja01FfeMAArTkFh8h90=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "AkcyK3pmbkYWNXuTUCMosKjWdFI69KwoGRx6IZTZ5W4="
            ],

            "https://testsafebrowsing.appspot.com/s/unknown.exe": [    "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "EU+4PoBMQp8xDjtI0KnGXfvNQrLvoTuvJuuZ7ff1ZgU=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "jiyG8wGn+faCRijKhB0eVogh/OGJyJWwO5RZTlrcX0I=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w="
            ],

            "https://testsafebrowsing.appspot.com/s/pua.exe": [    "X1qiRTjUNf5jh+KtQ3n4WBdBnqYPJlpuEopfLvZARsE=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "eUfZNURzQtpZkjmayohfwADaGQiF+TYizD/fSveVaoE=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE="
            ],

            "https://testsafebrowsing.appspot.com/apiv4/IOS/MALWARE/URL/": [    "z+nmEVNR0i8nIevlmsf/SAPyDLlmRfNla0J9lFBKL0A=",
                "e/8dHHRyCc1nJygNcHIJD6MTxyOphjISuJ4dYI6N//Y=",
                "6dT056kMid7yJkcBAQ/EtMiIj7b5ZuQKSIM1ZbXVb2U=",
                "pc1hwW5DPdxOpLODM+3to6nMq6J8tlH+x1Rcc3ZGAec=",
                "mqjxGQVdb+4TniGtrUdJAMBQnfSlpcJuidf+kulbI4s=",
                "fSk3abV8KY7dHqUi+j4rRi+cQYUZXYdCK2l9qOnsQl8=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pn7BBckKn7VVIbuLpRtKFCyprUR76hHEeu2/wk9QENg=",
                "8ieejNYYUpEh7oIOGvN9JulDqwUW8/aD0oe8rTfJiTw="
            ],

            "https://testsafebrowsing.appspot.com/apiv4/IOS/SOCIAL_ENGINEERING/URL/": [    "z+nmEVNR0i8nIevlmsf/SAPyDLlmRfNla0J9lFBKL0A=",
                "8ieejNYYUpEh7oIOGvN9JulDqwUW8/aD0oe8rTfJiTw=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pc1hwW5DPdxOpLODM+3to6nMq6J8tlH+x1Rcc3ZGAec=",
                "1YuwLFiyV04LoEMAto7PkowQEja/GiJ6zw3hGfMWVa8=",
                "QxOYSJfgAV4L+U5D4T/qBwxewHbgkRh0BAyr/hv5++0=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "3QVys10bmLf8FSnHUBPssDHSBT643hzC1amb6j+d5RY=",
                "jjNvi+uxmCf2o4/Ez/mvFexqbhtcFToh4Is6NG3wfds=",
                "mqjxGQVdb+4TniGtrUdJAMBQnfSlpcJuidf+kulbI4s="
            ],

            "https://testsafebrowsing.appspot.com/apiv4/OSX/MALWARE/URL/": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "wLY5edokPUYbpIzCtXyAz0IF0Q07GbV5VelNRSW9dmg=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "2CEUiw7mhFjNhq8TIiI76aCzpROmS77oPdls6xlyUhk=",
                "1WERk93rRv3o5dxCsOYtRU4KZIAXmzrtdfSuf4A/thc=",
                "z+nmEVNR0i8nIevlmsf/SAPyDLlmRfNla0J9lFBKL0A=",
                "mrIVR+25MZoIWl9H16j9WBvzfTNZZjkKmNv8oQAxClw=",
                "Ee71KYXUQNu9c41haqChHAcIsYqvNvDMuxXFTjpvJGs=",
                "pc1hwW5DPdxOpLODM+3to6nMq6J8tlH+x1Rcc3ZGAec=",
                "X+sIUgEgS6sNyXuMpOd1ifFT1eqRLxs/vQ3u0Pg+uSA="
            ],

            "https://testsafebrowsing.appspot.com/apiv4/OSX/SOCIAL_ENGINEERING/URL/": [    "z+nmEVNR0i8nIevlmsf/SAPyDLlmRfNla0J9lFBKL0A=",
                "mmq1foj+rZf+A+bWFizViELBcxlAuYk5TjV8O0WbeQE=",
                "DKl57kJ+kQB4bz9K9qQAva61Nlp5vlkq0zyQklx0dzM=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "wLY5edokPUYbpIzCtXyAz0IF0Q07GbV5VelNRSW9dmg=",
                "7DSV1uP+i/AYAFmF5j56rfqj7bWMJFMe4SoYSsgEsDw=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pc1hwW5DPdxOpLODM+3to6nMq6J8tlH+x1Rcc3ZGAec=",
                "2CEUiw7mhFjNhq8TIiI76aCzpROmS77oPdls6xlyUhk=",
                "KO5QZXQQsfv9CmIZCOR5aECB4mpEb/GRoMJcKpj1IBc="
            ],

            "https://testsafebrowsing.appspot.com/s/notif_pageload.html": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "wiNaFvPAyfCEawddu0uFeIV1Eu05diAVB+KK3FBosxU=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "uyXLl/ZGAm+Cxkf9yhQ7WE4ROuLTwRRsgPX/qXRqZFU="
            ],

            "https://testsafebrowsing.appspot.com/s/geoloc_click.html": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "MI28eSkq0BE/ZZF127IDuYWczMAoDPrILJrfl68f1RE=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "zr1+K46ArPwRRBfjbUN29pbz7ixLe+SjPlpujwX/iMw="
            ],

            "https://testsafebrowsing.appspot.com/s/notif_geoloc_delay.html": [    "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "kl6qHVByifRggN1vNItVDiLG3J/rpkwcAf5b+aSqHtU=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "/VzH6/7xh4kF/k4dtTOqCsM7KOWJPmcG1v3f305BiaA=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E="
            ],

            "https://testsafebrowsing.appspot.com/s/media_batch.html": [    "tTFmgRLUS9ZsBzzPJtEXA2TDgBVta4WaBU6kSNADnYU=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "AIiPYTkXl88AnqIpVpHdIgZZ+jehBlYWicrhasyHPZo=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE="
            ],

            "https://testsafebrowsing.appspot.com/s/midi_click.html": [    "RdiXHXuY2quSflNCVbUnTZdHvpaCQOd6+Nw8Sc+JxtU=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "OXugPEDqfNpByAX/fpg18VW4+me8xr05UGD7OP8LHWI=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE="
            ],

            "https://testsafebrowsing.appspot.com/s/bad_login.html": [    "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "I/PlErlgZ5wbo8I6gHEhlEM4HeOaVrbMxpw/tQdo4HQ=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY=",
                "kVfz32kLyClMtyT1saLhdXyzvC1pIkZw9wF0qNGmrRM="
            ],

            "https://testsafebrowsing.appspot.com/s/low_rep_login.html": [    "wsMtz1GbyPRv88fAf6g9asLoCKlMflpRZWSwSMz5nb8=",
                "5LHQQeEFQDzEIy87A/FRJOxSE5h1gllPDxitaGWLf1w=",
                "GrKy4W7cakmSUR5FwiFuAp8qTCym/b/SNkGBr11IGTE=",
                "fibhxM7Ip6AU1CvatgvXKdbWkvLVV6HR6SQ3JvrOTMc=",
                "1aBUzbFG9BknB+jc06PkAUscR06bSKE86nrqAglQX8E=",
                "pndXuMT6JnwSlt6nSrMcMFwEXdhZF6AXYmw/YK/O/OY="
            ]
        ]
        
        for (key, value) in expectedHashes {
            if let url = URL(string: key) {
                let calculatedHashes = Set<String>(SafeBrowsing.hashPrefixes(url))
                let expectedHashes = Set<String>(value)
                
                if expectedHashes.isDisjoint(with: calculatedHashes) {
                    XCTFail("Invalid Hashes for URL: \(key)")
                }
            } else {
                XCTFail("Invalid URL: \(key)")
            }
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
 
 func main() {
     retries := 3
     n := 1 << uint(retries)
 
     for i := 1;  i<= 10; ++i {
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

/** Expected Hash values are taken from Google's Safe-Browsing Go-Lang implementation!   **/
/** After stripping the code we get (which can be used to verify our algorithm is correct):
 
 func main() {
     urls := [...]string{
         "https://testsafebrowsing.appspot.com/s/phishing.html",
         "https://testsafebrowsing.appspot.com/s/malware.html",
         "https://testsafebrowsing.appspot.com/s/malware_in_iframe.html",
         "https://testsafebrowsing.appspot.com/s/unwanted.html",
         "https://testsafebrowsing.appspot.com/s/image_small.html",
         "https://testsafebrowsing.appspot.com/s/image_medium.html",
         "https://testsafebrowsing.appspot.com/s/image_large.html",
         "https://testsafebrowsing.appspot.com/s/bad_css.html",
         "https://testsafebrowsing.appspot.com/s/bad_javascript.html",
         "https://testsafebrowsing.appspot.com/s/trick_to_bill.html",

         "https://testsafebrowsing.appspot.com/s/content.exe",
         "https://testsafebrowsing.appspot.com/s/badrep.exe",
         "https://testsafebrowsing.appspot.com/s/unknown.exe",
         "https://testsafebrowsing.appspot.com/s/pua.exe",

         "https://testsafebrowsing.appspot.com/apiv4/IOS/MALWARE/URL/",
         "https://testsafebrowsing.appspot.com/apiv4/IOS/SOCIAL_ENGINEERING/URL/",
         "https://testsafebrowsing.appspot.com/apiv4/OSX/MALWARE/URL/",
         "https://testsafebrowsing.appspot.com/apiv4/OSX/SOCIAL_ENGINEERING/URL/",

         "https://testsafebrowsing.appspot.com/s/notif_pageload.html",
         "https://testsafebrowsing.appspot.com/s/geoloc_click.html",
         "https://testsafebrowsing.appspot.com/s/notif_geoloc_delay.html",
         "https://testsafebrowsing.appspot.com/s/media_batch.html",
         "https://testsafebrowsing.appspot.com/s/midi_click.html",

         "https://testsafebrowsing.appspot.com/s/bad_login.html",

         "https://testsafebrowsing.appspot.com/s/low_rep_login.html"}

     for i := 0; i < len(urls); ++i {
         fmt.Printf("Hashes for URL: %s\n", urls[i])
         hashes, _ := generateHashes(urls[i])
         for key, _ := range hashes {
             fmt.Printf("\t%s\n", base64.StdEncoding.EncodeToString([]byte(key)))
         }
         fmt.Print("\n")
     }
 */
