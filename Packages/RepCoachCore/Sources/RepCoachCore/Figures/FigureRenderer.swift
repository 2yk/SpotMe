import Foundation

/// A point on the figure's flat drawing, in the same units as its 200 × 200 box.
public struct FigurePoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

/// One thing to draw: round caps and joins always. Colours are 0xRRGGBB.
public enum FigureItem: Equatable, Sendable {
    case line(points: [FigurePoint], width: Double, color: UInt32, opacity: Double, dashed: Bool)
    case polygon(points: [FigurePoint], width: Double, color: UInt32, fill: UInt32?, fillOpacity: Double,
                 opacity: Double)
    case circle(center: FigurePoint, radius: Double, color: UInt32, opacity: Double)
}

/// What a part of the figure is, for the draw order: props first, then limbs, the load, the torso, the head.
public enum FigurePartKind: Int, Sendable {
    case prop, limb, load, torso, head

    /// Ties in depth go props, limbs, load, torso, head.
    var priority: Double {
        switch self {
        case .prop: 0
        case .limb: 1
        case .load: 1.5
        case .torso: 2
        case .head: 3
        }
    }
}

/// A part that can be sorted by depth: its items, and the black edge a limb gets when it is drawn over the torso.
public struct FigurePart: Sendable {
    public let key: String
    public let kind: FigurePartKind
    public let depth: Double
    public let items: [FigureItem]
    public let halo: [FigureItem]
}

/// The square window a figure is drawn in, the same at every angle.
public struct FigureCrop: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let side: Double
}

/// The renderer of design/figures/FIGURES.md, "The 3D format, complete": a straight port of `figure3d.py`.
/// Per frame: interpolate the two poses with ease in and out, turn them by yaw about the vertical axis through
/// the figure's centre, project orthographically, sort the parts far to near and dim limbs behind the body.
public enum FigureRenderer {
    static let white: UInt32 = 0xFFFFFF
    static let prop: UInt32 = 0x8E8E93
    static let volt: UInt32 = 0xCCFF3D
    static let halo: UInt32 = 0x000000
    public static let floorColor: UInt32 = 0x3A3A3C
    static let limbWidth = 9.0, torsoWidth = 12.0, headRadius = 11.0
    static let haloWidth = 2.5, haloTrim = 11.0
    static let dimFrom = 3.0, dimDepth = 15.0
    static let air = 10.0, minSide = 130.0, cropStep = 5

    static let upper: Set<String> = ["head", "neck", "shoulderL", "shoulderR", "elbowL", "elbowR", "handL", "handR"]

    // MARK: Poses and projection

    /// The middle of the x range and of the z range over all points of both poses.
    public static func centre(_ figure: Figure) -> (x: Double, z: Double) {
        let points = Array(figure.start.values) + Array(figure.end.values)
        let xs = points.map(\.x), zs = points.map(\.z)
        return ((xs.min()! + xs.max()!) / 2, (zs.min()! + zs.max()!) / 2)
    }

    /// Ease in and out: 0 at the start pose, 1 at the end pose.
    public static func ease(_ k: Double) -> Double { (1 - cos(Double.pi * k)) / 2 }

    /// The pose at `k` (0 = start, 1 = end).
    public static func pose(_ figure: Figure, k: Double) -> Figure.Pose {
        figure.start.reduce(into: [:]) { out, entry in
            let end = figure.end[entry.key] ?? entry.value
            out[entry.key] = entry.value + (end - entry.value) * k
        }
    }

    /// Screen x and y, and the depth toward the viewer, of a point turned by `yaw` degrees.
    public static func project(_ p: Vec3, yaw: Double, centre c: (x: Double, z: Double))
        -> (x: Double, y: Double, depth: Double) {
        let t = yaw * Double.pi / 180
        let dx = p.x - c.x, dz = p.z - c.z
        return (c.x + dx * cos(t) - dz * sin(t), p.y, dx * sin(t) + dz * cos(t))
    }

    private static func screen(_ p: Vec3, _ yaw: Double, _ c: (x: Double, z: Double)) -> FigurePoint {
        let q = project(p, yaw: yaw, centre: c)
        return FigurePoint(q.x, q.y)
    }

    /// 0xFFFFFF toward 0x6E6E73.
    static func blend(_ t: Double) -> UInt32 {
        let a: [Double] = [255, 255, 255], b: [Double] = [0x6E, 0x6E, 0x73]
        let channels = zip(a, b).map { UInt32(($0 + ($1 - $0) * t).rounded()) }
        return channels[0] << 16 | channels[1] << 8 | channels[2]
    }

    // MARK: Parts

    /// All depth-sortable parts of `pose` at `yaw`, always the same parts in the same order: each prop, armL,
    /// legL, armR, legR, torso, head, and the load if there is one.
    public static func parts(_ figure: Figure, pose p: Figure.Pose, yaw: Double,
                             centre c: (x: Double, z: Double)) -> [FigurePart] {
        var xy: [String: FigurePoint] = [:], depth: [String: Double] = [:]
        for (name, v) in p {
            let q = project(v, yaw: yaw, centre: c)
            xy[name] = FigurePoint(q.x, q.y)
            depth[name] = q.depth
        }
        let mid = (depth["neck"]! + depth["pelvis"]!) / 2
        var out: [FigurePart] = []

        for (index, prop) in figure.props.enumerated() {
            switch prop {
            case .line(let points, let width):
                let projected = points.map { project($0, yaw: yaw, centre: c) }
                out.append(FigurePart(
                    key: "prop\(index)", kind: .prop, depth: projected.map(\.depth).reduce(0, +) / Double(projected.count),
                    items: [.line(points: projected.map { FigurePoint($0.x, $0.y) }, width: width, color: Self.prop,
                                  opacity: 1, dashed: false)], halo: []))
            case .slab(let line, let z0, let z1, let width):
                var items: [FigureItem] = [], depths: [Double] = []
                for (a, b) in zip(line, line.dropFirst()) {
                    let quad = [Vec3(a[0], a[1], z0), Vec3(b[0], b[1], z0), Vec3(b[0], b[1], z1), Vec3(a[0], a[1], z1)]
                        .map { project($0, yaw: yaw, centre: c) }
                    items.append(.polygon(points: quad.map { FigurePoint($0.x, $0.y) }, width: width, color: Self.prop,
                                          fill: Self.prop, fillOpacity: 1, opacity: 1))
                    depths += quad.map(\.depth)
                }
                out.append(FigurePart(key: "prop\(index)", kind: .prop,
                                      depth: depths.isEmpty ? 0 : depths.reduce(0, +) / Double(depths.count),
                                      items: items, halo: []))
            }
        }

        var riding: [String: [Prim]] = [:]
        for load in figure.loads {
            for (key, prims) in loadPrims(load, p) { riding[key, default: []].append(contentsOf: prims) }
        }

        for side in ["L", "R"] {
            for (limb, chain) in [("arm", ["shoulder" + side, "elbow" + side, "hand" + side]),
                                  ("leg", ["hip" + side, "knee" + side, "ankle" + side, "toe" + side])] {
                let d = chain.map { depth[$0]! }.reduce(0, +) / Double(chain.count)
                // Dimmed by where the upper bone sits (a shin bent back does not grey a front-view leg).
                let upperBone = (depth[chain[0]]! + depth[chain[1]]!) / 2
                let dim = min(1, max(0, (mid - upperBone - dimFrom) / (dimDepth - dimFrom)))
                let points = chain.map { xy[$0]! }
                var items: [FigureItem] = [.line(points: points, width: limbWidth, color: blend(dim), opacity: 1,
                                                 dashed: false)]
                let a = points[0], b = points[1]
                let t = min(0.45, haloTrim / max(hypot(b.x - a.x, b.y - a.y), 1e-6))
                let first = FigurePoint(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
                let edge: [FigureItem] = [.line(points: [first] + Array(points.dropFirst()),
                                                width: limbWidth + 2 * haloWidth, color: halo, opacity: 1,
                                                dashed: false)]
                for load in figure.loads where limb == "arm" && load.type == "dumbbells" {
                    items += dumbbell(p["hand" + side]!, load.axis ?? Vec3(1, 0, 0), yaw, c, 1 - 0.45 * dim)
                }
                if let prims = riding[limb + side] {
                    items += primItems(prims, yaw, c, opacity: 1 - 0.45 * dim).items
                }
                out.append(FigurePart(key: limb + side, kind: .limb, depth: d, items: items, halo: edge))
            }
        }

        out.append(FigurePart(
            key: "torso", kind: .torso, depth: mid,
            items: [.line(points: [xy["shoulderL"]!, xy["neck"]!, xy["shoulderR"]!], width: torsoWidth, color: white,
                          opacity: 1, dashed: false),
                    .line(points: [xy["neck"]!, xy["pelvis"]!], width: torsoWidth, color: white, opacity: 1, dashed: false),
                    .line(points: [xy["hipL"]!, xy["pelvis"]!, xy["hipR"]!], width: torsoWidth, color: white, opacity: 1,
                          dashed: false)], halo: []))
        out.append(FigurePart(key: "head", kind: .head, depth: depth["head"]!,
                              items: [.circle(center: xy["head"]!, radius: headRadius, color: white, opacity: 1)],
                              halo: []))
        if let prims = riding["load"] {
            let (items, depths) = primItems(prims, yaw, c, opacity: nil)
            out.append(FigurePart(key: "load", kind: .load, depth: depths.reduce(0, +) / Double(depths.count),
                                  items: items, halo: []))
        }
        return out
    }

    /// Indices of `parts` far to near. Equal depths (to 0.1) go props, limbs, load, torso, head, then list order.
    public static func order(_ parts: [FigurePart]) -> [Int] {
        parts.indices.sorted { i, j in
            let a = ((parts[i].depth * 10).rounded() / 10, parts[i].kind.priority, i)
            let b = ((parts[j].depth * 10).rounded() / 10, parts[j].kind.priority, j)
            return a < b
        }
    }

    /// Everything to draw, far to near; a limb drawn after the torso comes with its black edge first.
    public static func draw(_ parts: [FigurePart]) -> [FigureItem] {
        var out: [FigureItem] = []
        var seenTorso = false
        for index in order(parts) {
            let part = parts[index]
            if part.kind == .limb && seenTorso { out += part.halo }
            out += part.items
            seenTorso = seenTorso || part.kind == .torso
        }
        return out
    }

    /// The draw list of `pose` at `yaw`, without the floor line.
    public static func drawList(_ figure: Figure, pose: Figure.Pose, yaw: Double) -> [FigureItem] {
        draw(parts(figure, pose: pose, yaw: yaw, centre: centre(figure)))
    }

    // MARK: Crop

    /// One square per figure, the same at every angle: the bounds of both poses at yaw 0, 5, … 355, with the
    /// floor, at least `minSide` wide, with `air` around.
    public static func crop(_ figure: Figure) -> FigureCrop {
        let c = centre(figure)
        var x0 = Double.infinity, y0 = Double.infinity, x1 = -Double.infinity, y1 = -Double.infinity
        func tenth(_ v: Double) -> Double { (v * 10).rounded() / 10 }
        for yaw in stride(from: 0, to: 360, by: cropStep) {
            for pose in [figure.start, figure.end] {
                for part in parts(figure, pose: pose, yaw: Double(yaw), centre: c) {
                    for item in part.items {
                        switch item {
                        case .circle(let center, let radius, _, _):
                            x0 = min(x0, tenth(center.x) - radius); x1 = max(x1, tenth(center.x) + radius)
                            y0 = min(y0, tenth(center.y) - radius); y1 = max(y1, tenth(center.y) + radius)
                        case .line(let points, let width, _, _, _), .polygon(let points, let width, _, _, _, _):
                            for point in points {
                                x0 = min(x0, tenth(point.x) - width / 2); x1 = max(x1, tenth(point.x) + width / 2)
                                y0 = min(y0, tenth(point.y) - width / 2); y1 = max(y1, tenth(point.y) + width / 2)
                            }
                        }
                    }
                }
            }
        }
        y0 = min(y0, figure.floor - 1)
        y1 = max(y1, figure.floor + 1)
        let side = max(minSide, x1 - x0 + 2 * air, y1 - y0 + 2 * air)
        return FigureCrop(x: (x0 + x1 - side) / 2, y: (y0 + y1 - side) / 2, side: side)
    }

    // MARK: Loads

    /// 3D drawing primitives of a load: a polyline, a ring, a ball, a filled quad.
    enum Prim {
        case seg([Vec3], UInt32, Double, Bool)
        case disc(Vec3, Vec3, Double, UInt32, Double)
        case ball(Vec3, Double)
        case quad([Vec3], UInt32)
    }

    private static func names(_ at: PointSpec) -> [String] { at.names }

    private static func point(_ p: Figure.Pose, _ at: PointSpec, _ offset: Vec3? = nil) -> Vec3 {
        let ns = names(at)
        let sum = ns.reduce(Vec3.zero) { $0 + p[$1]! }
        return sum * (1 / Double(ns.count)) + (offset ?? .zero)
    }

    /// The body's right-to-left axis where the load sits: shoulders for the upper body, hips below.
    private static func across(_ p: Figure.Pose, _ at: PointSpec) -> Vec3 {
        let up = names(at).contains { upper.contains($0) }
        let (a, b) = up ? ("shoulderR", "shoulderL") : ("hipR", "hipL")
        let u = (p[b]! - p[a]!).unit
        return u.isZero ? Vec3(0, 0, 1) : u
    }

    /// The limb a one-sided load piece rides with.
    private static func owner(_ at: PointSpec) -> String {
        let ns = names(at)
        return (ns.contains { upper.contains($0) } ? "arm" : "leg") + String(ns[0].last!)
    }

    private static func loadPrims(_ ld: Load, _ p: Figure.Pose) -> [String: [Prim]] {
        var out: [String: [Prim]] = [:]
        func put(_ key: String, _ prims: Prim...) { out[key, default: []].append(contentsOf: prims) }
        let hands = PointSpec.one("hands")

        switch ld.type {
        case "bar":
            let at = ld.at ?? hands
            let half = (ld.length ?? 80) / 2, plate = ld.plate ?? 14
            let m: Vec3, u: Vec3
            if case .one("hands") = at {
                m = point(p, hands)
                let along = (p["handL"]! - p["handR"]!).unit
                u = along.isZero ? across(p, at) : along
            } else {
                m = point(p, at, ld.offset)
                u = across(p, at)
            }
            let limb = names(at).contains { upper.contains($0) } ? "arm" : "leg"
            for (side, sign) in [("L", 1.0), ("R", -1.0)] {
                put(limb + side, .seg([m, m + u * (sign * half)], volt, 4, false))
                if plate != 0 {
                    put(limb + side, .disc(m + u * (sign * (half - 6)), u, plate, volt, 4.5))
                }
            }
        case "cable", "band":
            let anchor = ld.anchor ?? .zero
            let handle = ld.handle ?? "grip"
            let dashed = ld.type == "band"
            if handle == "grip" {
                let at = ld.at ?? .one("handL")
                let q = point(p, at)
                var d = (q - anchor).unit.cross(across(p, at)).unit
                if d.isZero { d = across(p, at) }
                put(owner(at), .seg([anchor, q], volt, 2.5, dashed), .seg([q - d * 6, q + d * 6], volt, 5, false))
            } else {
                let m = point(p, hands)
                var u = (p["handL"]! - p["handR"]!).unit
                if u.isZero { u = across(p, hands) }
                if handle == "bar" {
                    put("load", .seg([anchor, m], volt, 2.5, dashed),
                        .seg([p["handR"]! - u * 5, p["handL"]! + u * 5], volt, 5, false))
                } else {
                    // A rope: a knot a little toward the anchor, two tails to the hands.
                    let knot = m + (anchor - m).unit * 7
                    put("load", .seg([anchor, knot], volt, 2.5, dashed),
                        .seg([p["handL"]!, knot, p["handR"]!], volt, 4, false))
                }
            }
        case "machine":
            let grips = ld.grips ?? ["handL", "handR"]
            let axis = (ld.axis ?? Vec3(0, 1, 0)).unit
            let half = (ld.length ?? 14) / 2
            for (index, grip) in grips.enumerated() {
                let q = p[grip]!
                if let pivots = ld.pivots {
                    put(owner(.one(grip)), .seg([pivots[index], q], prop, 4, false))
                }
                put(owner(.one(grip)), .seg([q - axis * half, q + axis * half], volt, 6, false))
            }
        case "pad":
            guard let at = ld.at else { break }
            let q = point(p, at, ld.offset), u = across(p, at), half = (ld.length ?? 22) / 2, w = ld.w ?? 10
            if at.isString {
                if let pivot = ld.pivot { put(owner(at), .seg([pivot, q], prop, 4, false)) }
                put(owner(at), .seg([q - u * half, q + u * half], volt, w, false))
            } else {
                // Across both limbs: split in the middle, each half rides with its side.
                let limb = names(at).contains { upper.contains($0) } ? "arm" : "leg"
                if let pivot = ld.pivot {
                    let d = pivot - q
                    let side = d.x * u.x + d.y * u.y + d.z * u.z >= 0 ? "L" : "R"
                    put(limb + side, .seg([pivot, q], prop, 4, false))
                }
                put(limb + "L", .seg([q, q + u * half], volt, w, false))
                put(limb + "R", .seg([q, q - u * half], volt, w, false))
            }
        case "platform":
            let q = point(p, ld.at ?? .many(["ankleL", "ankleR"]), ld.offset)
            let a = (ld.angle ?? 90) * Double.pi / 180
            let length = ld.length ?? 40
            let d = Vec3(cos(a) * length / 2, sin(a) * length / 2, 0)
            let z = Vec3(0, 0, (ld.width ?? 34) / 2)
            put("load", .quad([q + d + z, q - d + z, q - d - z, q + d - z], volt))
        case "held":
            let kind = ld.kind ?? "plate"
            let at = ld.at ?? hands
            let q = point(p, at, ld.offset)
            let u = ld.axis.map(\.unit) ?? across(p, at)
            switch kind {
            case "plate": put("load", .disc(q, u, 11, volt, 4))
            case "wheel": put("load", .disc(q, u, 9, volt, 5))
            case "ball": put("load", .ball(q, 9))
            default:  // A kettlebell: the handle across the hands, the bell hanging below.
                put("load", .seg([q - u * 4, q + u * 4], volt, 3, false), .ball(q + Vec3(0, 10, 0), 7))
            }
        default:
            break
        }
        return out
    }

    private static func discRim(_ centre: Vec3, _ axis: Vec3, _ r: Double, _ n: Int = 16) -> [Vec3] {
        let u = axis.unit
        var e1 = u.cross(Vec3(0, 1, 0)).unit
        if e1.isZero { e1 = u.cross(Vec3(1, 0, 0)).unit }
        let e2 = u.cross(e1)
        return (0..<n).map { i in
            let angle = 2 * Double.pi * Double(i) / Double(n)
            return centre + e1 * (r * cos(angle)) + e2 * (r * sin(angle))
        }
    }

    /// The items of some primitives and the depths of their 3D points. `opacity` is nil for a part of its own.
    private static func primItems(_ prims: [Prim], _ yaw: Double, _ c: (x: Double, z: Double), opacity: Double?)
        -> (items: [FigureItem], depths: [Double]) {
        var items: [FigureItem] = [], depths: [Double] = []
        let op = opacity ?? 1
        for prim in prims {
            switch prim {
            case .seg(let points, let color, let width, let dashed):
                let projected = points.map { project($0, yaw: yaw, centre: c) }
                items.append(.line(points: projected.map { FigurePoint($0.x, $0.y) }, width: width, color: color,
                                   opacity: op, dashed: dashed))
                depths += projected.map(\.depth)
            case .disc(let centre, let axis, let r, let color, let width):
                let rim = discRim(centre, axis, r).map { project($0, yaw: yaw, centre: c) }
                items.append(.polygon(points: rim.map { FigurePoint($0.x, $0.y) }, width: width, color: color, fill: nil,
                                      fillOpacity: 1, opacity: op))
                depths.append(project(centre, yaw: yaw, centre: c).depth)
            case .quad(let points, let color):
                let projected = points.map { project($0, yaw: yaw, centre: c) }
                items.append(.polygon(points: projected.map { FigurePoint($0.x, $0.y) }, width: 5, color: color,
                                      fill: color, fillOpacity: 0.28 * op, opacity: op))
                depths += projected.map(\.depth)
            case .ball(let centre, let r):
                let q = project(centre, yaw: yaw, centre: c)
                items.append(.circle(center: FigurePoint(q.x, q.y), radius: r, color: volt, opacity: op))
                depths.append(q.depth)
            }
        }
        return (items, depths)
    }

    /// A dumbbell in a hand: a bar 18 long with a cap across each end.
    private static func dumbbell(_ hand: Vec3, _ axis: Vec3, _ yaw: Double, _ c: (x: Double, z: Double),
                                 _ opacity: Double) -> [FigureItem] {
        let u = axis.unit
        // The caps lie across the bar, vertical unless the bar is vertical.
        var cr = abs(u.z) < 0.9 ? Vec3(-u.y, u.x, 0) : Vec3(0, 1, 0)
        let m = cr.length == 0 ? 1 : cr.length
        cr = abs(u.y) < 0.9 ? cr * (1 / m) : Vec3(0, 0, 1)
        let ends = [-1.0, 1.0].map { hand + u * (9 * $0) }
        var items: [FigureItem] = [.line(points: ends.map { screen($0, yaw, c) }, width: 7, color: volt,
                                         opacity: opacity, dashed: false)]
        for end in ends {
            items.append(.line(points: [screen(end - cr * 6.5, yaw, c), screen(end + cr * 6.5, yaw, c)], width: 4.5,
                               color: volt, opacity: opacity, dashed: false))
        }
        return items
    }
}
