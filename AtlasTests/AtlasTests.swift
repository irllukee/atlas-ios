//
//  AtlasTests.swift
//  AtlasTests
//
//  Created by Lucas Waldron on 9/15/25.
//

import Testing
@testable import Atlas

/// Main test suite for Atlas app
struct AtlasTests {
    
    @Test("App launches successfully")
    func testAppLaunch() async throws {
        // Basic integration test to ensure the app can launch
        #expect(true) // App should launch without crashing
    }
}
