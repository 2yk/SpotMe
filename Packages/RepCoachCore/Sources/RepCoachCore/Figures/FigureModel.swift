import Foundation

/// A point in a figure's drawing space: x right, y down, z toward the viewer (from the usual view).
public struct Vec3: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    static let zero = Vec3(0, 0, 0)

    static func + (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x + b.x, a.y + b.y, a.z + b.z) }
    static func - (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x - b.x, a.y - b.y, a.z - b.z) }
    static func * (a: Vec3, k: Double) -> Vec3 { Vec3(a.x * k, a.y * k, a.z * k) }

    var length: Double { (x * x + y * y + z * z).squareRoot() }
    var isZero: Bool { x == 0 && y == 0 && z == 0 }

    /// Unit length; the zero vector stays zero.
    var unit: Vec3 { length > 1e-9 ? self * (1 / length) : .zero }

    func cross(_ b: Vec3) -> Vec3 { Vec3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x) }
}

extension Vec3: Decodable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.init(try container.decode(Double.self), try container.decode(Double.self),
                  try container.decode(Double.self))
    }
}

/// The figures that ship with the app and the exercises they belong to (`figures.json`, built by the
/// designer's `bundle.py`; never edited by hand).
public struct FigureBundle: Decodable, Sendable {
    public struct Entry: Decodable, Sendable {
        /// The figure to show.
        public let figure: String
        /// A short cue, 72 characters at most.
        public let cue: String
    }

    public let version: Int
    /// By plan exerciseId; several exercises can share a figure.
    public let exercises: [String: Entry]
    public let figures: [String: Figure]
}

/// Two poses of seventeen points, props and a load: everything needed to draw an exercise from any side.
public struct Figure: Decodable, Sendable {
    public typealias Pose = [String: Vec3]

    public let id: String
    /// y of the floor line.
    public let floor: Double
    /// Seconds per rep.
    public let tempo: Double
    public let hold: Bool
    /// The opening view, in degrees: the angle the figure is first shown at, and where the Crown starts.
    public let yaw: Double
    public let props: [Prop]
    public let loads: [Load]
    public let start: Pose
    public let end: Pose

    private enum CodingKeys: String, CodingKey {
        case id, floor, tempo, hold, yaw, props, load, start, end
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        floor = try c.decodeIfPresent(Double.self, forKey: .floor) ?? 182
        tempo = try c.decodeIfPresent(Double.self, forKey: .tempo) ?? 2.6
        hold = try c.decodeIfPresent(Bool.self, forKey: .hold) ?? false
        yaw = try c.decodeIfPresent(Double.self, forKey: .yaw) ?? 0
        props = try c.decodeIfPresent([Prop].self, forKey: .props) ?? []
        if let list = try? c.decode([Load].self, forKey: .load) {
            loads = list
        } else if let one = try? c.decode(Load.self, forKey: .load) {
            loads = [one]
        } else {
            loads = []
        }
        start = try c.decode(Pose.self, forKey: .start)
        end = try c.decode(Pose.self, forKey: .end)
    }

    /// The opening view as 0..<360.
    public var openingYaw: Double {
        let turned = yaw.truncatingRemainder(dividingBy: 360)
        return turned < 0 ? turned + 360 : turned
    }
}

/// Grey scenery that never moves: a bench, a pull-up bar, a cable column.
public enum Prop: Decodable, Sendable {
    /// A polyline in 3D.
    case line(points: [Vec3], width: Double)
    /// An x-y polyline swept from z0 to z1: a wall, a bench top seen from the side.
    case slab(points: [[Double]], z0: Double, z1: Double, width: Double)

    private enum CodingKeys: String, CodingKey {
        case line, slab, z, w
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let width = try c.decodeIfPresent(Double.self, forKey: .w) ?? 6
        if let line = try c.decodeIfPresent([Vec3].self, forKey: .line) {
            self = .line(points: line, width: width)
        } else {
            let z = try c.decode([Double].self, forKey: .z)
            self = .slab(points: try c.decode([[Double]].self, forKey: .slab), z0: z[0], z1: z[1], width: width)
        }
    }
}

/// A point spec: a body point name, "hands" (the mean of both), or a list of names (their mean).
public enum PointSpec: Decodable, Sendable {
    case one(String)
    case many([String])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let one = try? c.decode(String.self) {
            self = .one(one)
        } else {
            self = .many(try c.decode([String].self))
        }
    }

    var names: [String] {
        switch self {
        case .one("hands"): ["handL", "handR"]
        case .one(let name): [name]
        case .many(let names): names
        }
    }

    /// A single string, "hands" included (a list of names is the other case).
    var isString: Bool {
        if case .one = self { true } else { false }
    }
}

/// What the figure carries, in volt, moving with the body. Fields not listed for a type are ignored.
public struct Load: Decodable, Sendable {
    public let type: String
    public let axis: Vec3?
    public let at: PointSpec?
    public let offset: Vec3?
    public let length: Double?
    public let plate: Double?
    public let anchor: Vec3?
    public let handle: String?
    public let grips: [String]?
    public let pivots: [Vec3]?
    public let pivot: Vec3?
    public let w: Double?
    public let angle: Double?
    public let width: Double?
    public let kind: String?

    public init(from decoder: Decoder) throws {
        enum Key: String, CodingKey {
            case type, axis, at, offset, length, plate, anchor, handle, grips, pivots, pivot, w, angle, width, kind
        }
        let c = try decoder.container(keyedBy: Key.self)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "none"
        axis = try c.decodeIfPresent(Vec3.self, forKey: .axis)
        at = try c.decodeIfPresent(PointSpec.self, forKey: .at)
        offset = try c.decodeIfPresent(Vec3.self, forKey: .offset)
        length = try c.decodeIfPresent(Double.self, forKey: .length)
        plate = try c.decodeIfPresent(Double.self, forKey: .plate)
        anchor = try c.decodeIfPresent(Vec3.self, forKey: .anchor)
        handle = try c.decodeIfPresent(String.self, forKey: .handle)
        grips = try c.decodeIfPresent([String].self, forKey: .grips)
        pivots = try c.decodeIfPresent([Vec3].self, forKey: .pivots)
        pivot = try c.decodeIfPresent(Vec3.self, forKey: .pivot)
        w = try c.decodeIfPresent(Double.self, forKey: .w)
        angle = try c.decodeIfPresent(Double.self, forKey: .angle)
        width = try c.decodeIfPresent(Double.self, forKey: .width)
        kind = try c.decodeIfPresent(String.self, forKey: .kind)
    }
}

/// The figures that ship with the app.
public struct FigureLibrary: Sendable {
    public let bundle: FigureBundle

    /// `figures.json` from the package's resources.
    public static let shared: FigureLibrary? = {
        guard let url = Bundle.module.url(forResource: "figures", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundle = try? JSONDecoder().decode(FigureBundle.self, from: data) else { return nil }
        return FigureLibrary(bundle: bundle)
    }()

    public init(bundle: FigureBundle) {
        self.bundle = bundle
    }

    /// The figure of a plan exercise and its cue. nil for exercises without one (the user's own).
    public func figure(forExercise exerciseId: String) -> (figure: Figure, cue: String)? {
        guard let entry = bundle.exercises[exerciseId], let figure = bundle.figures[entry.figure] else { return nil }
        return (figure, entry.cue)
    }
}
