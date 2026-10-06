import XCTest
@testable import RepCoachCore

/// The renderer against `design/figures/bundle/vectors.json`, the designer's golden values from `figure3d.py`:
/// projected points, part order, black edges, depths, crop, and the whole draw list at yaw 40.
final class FigureTests: XCTestCase {
    struct Vectors: Decodable {
        struct Case: Decodable {
            let yaw: Double
            let k: Double
            let points: [String: [Double]]
            let order: [String]
            let edge: [String]
            let depths: [String: Double]
            let draw: [DrawItem]?
        }
        let figures: [String: Entry]
        struct Entry: Decodable {
            let centre: [Double]
            let crop: [Double]
            let cases: [Case]
        }
    }

    /// [tag, points or circle, stroke width, colour, fill, stroke opacity, dash, fill opacity]
    struct DrawItem: Decodable {
        let tag: String
        let points: [[Double]]
        let circle: [Double]
        let width: Double
        let color: String
        let fill: String
        let opacity: Double
        let dash: String
        let fillOpacity: Double

        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            tag = try c.decode(String.self)
            if tag == "circle" {
                circle = try c.decode([Double].self)
                points = []
            } else {
                points = try c.decode([[Double]].self)
                circle = []
            }
            width = try c.decode(Double.self)
            color = try c.decode(String.self)
            fill = try c.decode(String.self)
            opacity = try c.decode(Double.self)
            dash = try c.decode(String.self)
            fillOpacity = try c.decode(Double.self)
        }
    }

    func vectors() throws -> Vectors {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "vectors", withExtension: "json"))
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    func library() throws -> FigureLibrary { try XCTUnwrap(FigureLibrary.shared) }

    func hex(_ value: UInt32) -> String { String(format: "#%06X", value) }

    // MARK: The bundle

    func testTheBundleHasFiftyFiguresAndEveryExercisePointsAtOne() throws {
        let bundle = try library().bundle
        XCTAssertEqual(bundle.figures.count, 50)
        XCTAssertEqual(bundle.exercises.count, 52)
        for (exercise, entry) in bundle.exercises {
            XCTAssertNotNil(bundle.figures[entry.figure], "\(exercise) has no figure \(entry.figure)")
            XCTAssertLessThanOrEqual(entry.cue.count, 72, "\(exercise)'s cue is too long")
        }
    }

    func testEveryTrainedExerciseOfThePlanHasAFigure() throws {
        let library = try library()
        let missing = try Plan.bundled().days.flatMap(\.items)
            .filter { $0.kind != .checklist && library.figure(forExercise: $0.exerciseId) == nil }
            .map(\.exerciseId)
        XCTAssertEqual(missing, [], "Exercises of the plan without a figure")
    }

    func testAnExerciseTheUserMadeHasNoFigure() throws {
        XCTAssertNil(try library().figure(forExercise: "custom-barbell-row"))
    }

    func testTheOpeningViewIsTheFigureYawOrZero() throws {
        let bundle = try library().bundle
        XCTAssertTrue(bundle.figures.values.contains { $0.openingYaw != 0 })
        XCTAssertTrue(bundle.figures.values.allSatisfy { (0..<360).contains($0.openingYaw) })
    }

    // MARK: Golden values

    func testCentreAndCropMatchTheReference() throws {
        let library = try library()
        for (id, entry) in try vectors().figures {
            let figure = try XCTUnwrap(library.bundle.figures[id])
            let centre = FigureRenderer.centre(figure)
            XCTAssertEqual(centre.x, entry.centre[0], accuracy: 0.02, id)
            XCTAssertEqual(centre.z, entry.centre[1], accuracy: 0.02, id)
            let crop = FigureRenderer.crop(figure)
            XCTAssertEqual(crop.x, entry.crop[0], accuracy: 0.2, "\(id) crop x")
            XCTAssertEqual(crop.y, entry.crop[1], accuracy: 0.2, "\(id) crop y")
            XCTAssertEqual(crop.side, entry.crop[2], accuracy: 0.2, "\(id) crop side")
        }
    }

    func testProjectionOrderAndEdgesMatchTheReference() throws {
        let library = try library()
        for (id, entry) in try vectors().figures {
            let figure = try XCTUnwrap(library.bundle.figures[id])
            let centre = FigureRenderer.centre(figure)
            for golden in entry.cases {
                let name = "\(id) yaw \(golden.yaw) k \(golden.k)"
                let pose = FigureRenderer.pose(figure, k: golden.k)
                for (point, expected) in golden.points {
                    let q = FigureRenderer.project(try XCTUnwrap(pose[point]), yaw: golden.yaw, centre: centre)
                    XCTAssertEqual(q.x, expected[0], accuracy: 0.02, "\(name) \(point) x")
                    XCTAssertEqual(q.y, expected[1], accuracy: 0.02, "\(name) \(point) y")
                    XCTAssertEqual(q.depth, expected[2], accuracy: 0.02, "\(name) \(point) depth")
                }
                let parts = FigureRenderer.parts(figure, pose: pose, yaw: golden.yaw, centre: centre)
                for part in parts {
                    XCTAssertEqual(part.depth, try XCTUnwrap(golden.depths[part.key]), accuracy: 0.02,
                                   "\(name) depth of \(part.key)")
                }
                let order = FigureRenderer.order(parts)
                XCTAssertEqual(order.map { parts[$0].key }, golden.order, name)
                var seenTorso = false
                var edges: [String] = []
                for index in order {
                    if parts[index].kind == .limb && seenTorso { edges.append(parts[index].key) }
                    seenTorso = seenTorso || parts[index].kind == .torso
                }
                XCTAssertEqual(edges, golden.edge, "\(name) edges")
            }
        }
    }

    func testTheDrawListAtYaw40MatchesTheReference() throws {
        let library = try library()
        for (id, entry) in try vectors().figures {
            let figure = try XCTUnwrap(library.bundle.figures[id])
            for golden in entry.cases where golden.draw != nil {
                let expected = try XCTUnwrap(golden.draw)
                let items = FigureRenderer.drawList(figure, pose: FigureRenderer.pose(figure, k: golden.k),
                                                    yaw: golden.yaw)
                XCTAssertEqual(items.count, expected.count, "\(id) draw list length")
                for (index, (item, want)) in zip(items, expected).enumerated() {
                    let name = "\(id) item \(index)"
                    switch item {
                    case .line(let points, let width, let color, let opacity, let dashed):
                        XCTAssertEqual(want.tag, "polyline", name)
                        XCTAssertEqual(opacity, want.opacity, accuracy: 0.06, "\(name) opacity")
                        XCTAssertEqual(width, want.width, accuracy: 0.01, name)
                        XCTAssertEqual(hex(color), want.color, name)
                        XCTAssertEqual(dashed ? "5 4" : "", want.dash, name)
                        assert(points, want.points, name)
                    case .polygon(let points, let width, let color, let fill, let fillOpacity, let opacity):
                        XCTAssertEqual(want.tag, "polygon", name)
                        XCTAssertEqual(opacity, want.opacity, accuracy: 0.06, "\(name) opacity")
                        XCTAssertEqual(fillOpacity, want.fillOpacity, accuracy: 0.06, "\(name) fill opacity")
                        XCTAssertEqual(width, want.width, accuracy: 0.01, name)
                        XCTAssertEqual(hex(color), want.color, name)
                        XCTAssertEqual(fill.map(hex) ?? "none", want.fill, name)
                        assert(points, want.points, name)
                    case .circle(let center, let radius, let color, let opacity):
                        XCTAssertEqual(want.tag, "circle", name)
                        XCTAssertEqual(opacity, want.opacity, accuracy: 0.06, "\(name) opacity")
                        XCTAssertEqual(center.x, want.circle[0], accuracy: 0.06, name)
                        XCTAssertEqual(center.y, want.circle[1], accuracy: 0.06, name)
                        XCTAssertEqual(radius, want.circle[2], accuracy: 0.06, name)
                        XCTAssertEqual(hex(color), want.color, name)
                    }
                }
            }
        }
    }

    /// The reference prints coordinates to one decimal.
    private func assert(_ points: [FigurePoint], _ expected: [[Double]], _ name: String) {
        XCTAssertEqual(points.count, expected.count, name)
        for (point, want) in zip(points, expected) {
            XCTAssertEqual(point.x, want[0], accuracy: 0.06, name)
            XCTAssertEqual(point.y, want[1], accuracy: 0.06, name)
        }
    }

    // MARK: Motion

    func testEaseAndPoseEndpoints() throws {
        XCTAssertEqual(FigureRenderer.ease(0), 0, accuracy: 1e-12)
        XCTAssertEqual(FigureRenderer.ease(0.5), 0.5, accuracy: 1e-12)
        XCTAssertEqual(FigureRenderer.ease(1), 1, accuracy: 1e-12)
        let figure = try XCTUnwrap(library().figure(forExercise: "incline-db-press")).figure
        XCTAssertEqual(FigureRenderer.pose(figure, k: 0), figure.start)
        XCTAssertEqual(FigureRenderer.pose(figure, k: 1), figure.end)
    }
}
