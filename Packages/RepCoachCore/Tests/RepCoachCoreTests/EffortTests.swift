import XCTest
import SwiftData
@testable import RepCoachCore

final class EffortTests: StoreTestCase {

    func testLevelsFollowApples() {
        let expected: [(Int, Effort.Level)] = [(1, .easy), (3, .easy), (4, .moderate), (6, .moderate),
                                               (7, .hard), (9, .hard), (10, .allOut)]
        for (score, level) in expected {
            XCTAssertEqual(Effort.level(score), level, "score \(score)")
        }
        XCTAssertEqual(Effort.text(7), "7 · Hard")
        XCTAssertEqual(Effort.text(10), "10 · All Out")
    }

    func testOnlyOneToTenIsValid() {
        XCTAssertEqual(Effort.valid(1), 1)
        XCTAssertEqual(Effort.valid(10), 10)
        XCTAssertNil(Effort.valid(0))
        XCTAssertNil(Effort.valid(11))
        XCTAssertNil(Effort.valid(nil))
    }

    func testTheRatingTravelsWithTheSession() throws {
        let session = try logSession("hammer-curl", on: sept(7), [(12.5, 11)])
        XCTAssertNil(SessionPayload(session).effort)
        session.effort = 7
        let payload = SessionPayload(session)
        XCTAssertEqual(SessionPayload(userInfo: payload.userInfo)?.effort, 7)

        // The phone stores it, and a re-send that adds the rating updates the copy it already has.
        let phone = try RepCoachStore.makeContainer(inMemory: true)
        let phoneContext = ModelContext(phone)
        var before = payload
        before.effort = nil
        let stored = try before.upsert(into: phoneContext)
        XCTAssertNil(stored.effort)
        _ = try payload.upsert(into: phoneContext)
        XCTAssertEqual(stored.effort, 7)
        // An older copy never takes the rating away.
        _ = try before.upsert(into: phoneContext)
        XCTAssertEqual(stored.effort, 7)
    }

    func testSessionsSentBeforeRatingsExistStillRead() throws {
        let session = try logSession("hammer-curl", on: sept(7), [(12.5, 11)])
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(SessionPayload(session)))
                                   as? [String: Any])
        object["effort"] = nil
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertNil(try JSONDecoder().decode(SessionPayload.self, from: data).effort)
    }

    func testARestoredCopyBringsTheRatingIntoTheWatchsOwnSession() throws {
        let local = try logSession("hammer-curl", on: sept(7), [(12.5, 11)])
        let restored = try logSession("preacher-curl", on: sept(7), dayKey: "monday", [(20, 10)])
        restored.effort = 6
        try SessionPayload(restored).merge(into: local, context: context)
        XCTAssertEqual(local.effort, 6)
        // The watch's own rating wins.
        local.effort = 9
        try SessionPayload(restored).merge(into: local, context: context)
        XCTAssertEqual(local.effort, 9)
    }

    func testHistoryCarriesTheSessionsRating() throws {
        let session = try logSession("hammer-curl", on: sept(7), [(12.5, 11)])
        session.effort = 5
        XCTAssertEqual(try history.entries(for: "hammer-curl").first?.effort, 5)
    }
}
