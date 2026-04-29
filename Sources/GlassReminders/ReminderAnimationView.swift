import AppKit
import GlassRemindersCore
import SwiftUI

struct ReminderAnimationView: View {
    let asset: ReminderAsset

    var body: some View {
        if let path = asset.customImagePath,
           FileManager.default.fileExists(atPath: path) {
            AnimatedImageView(path: path)
        } else if let url = bundledImageURL(named: asset.bundledImageName) {
            AnimatedImageView(path: url.path)
        } else {
            DefaultMotionGraphic(style: asset.style)
        }
    }

    private func bundledImageURL(named name: String?) -> URL? {
        guard let name, !name.isEmpty else {
            return nil
        }

        if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Animations") {
            return url
        }

        let workingDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let sourceURL = workingDirectoryURL
            .appendingPathComponent("Resources")
            .appendingPathComponent("Animations")
            .appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: sourceURL.path) ? sourceURL : nil
    }
}

struct AnimatedImageView: NSViewRepresentable {
    let path: String

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.clear.cgColor
        return imageView
    }

    func updateNSView(_ imageView: NSImageView, context: Context) {
        imageView.image = NSImage(contentsOfFile: path)
        imageView.animates = true
    }
}

struct DefaultMotionGraphic: View {
    let style: ReminderVisualStyle

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                switch style {
                case .water:
                    waterGraphic(t)
                case .eyeDrops:
                    eyeDropsGraphic(t)
                case .custom:
                    customGraphic(t)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func waterGraphic(_ t: TimeInterval) -> some View {
        let bob = sin(t * 2.4) * 8
        let ripple = 0.78 + (sin(t * 3.1) + 1) * 0.08

        return ZStack {
            Circle()
                .stroke(Color.cyan.opacity(0.26), lineWidth: 10)
                .scaleEffect(ripple)

            Teardrop()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.95), Color.blue.opacity(0.66)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 72, height: 108)
                .offset(y: bob)
                .shadow(color: .cyan.opacity(0.35), radius: 18)

            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 18, height: 18)
                .offset(x: -16, y: -22 + bob)
        }
    }

    private func eyeDropsGraphic(_ t: TimeInterval) -> some View {
        let dropY = CGFloat((sin(t * 2.2) + 1) * 26 - 28)

        return ZStack {
            EyeShape()
                .stroke(Color.indigo.opacity(0.72), lineWidth: 7)
                .frame(width: 132, height: 76)

            Circle()
                .fill(Color.indigo.opacity(0.82))
                .frame(width: 40, height: 40)

            Circle()
                .fill(Color.white.opacity(0.88))
                .frame(width: 12, height: 12)
                .offset(x: -8, y: -8)

            Teardrop()
                .fill(Color.cyan.opacity(0.88))
                .frame(width: 26, height: 40)
                .offset(x: 52, y: dropY)
                .shadow(color: .cyan.opacity(0.35), radius: 10)
        }
    }

    private func customGraphic(_ t: TimeInterval) -> some View {
        let spin = Angle(degrees: t.truncatingRemainder(dividingBy: 6) * 60)

        return ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 6)
                .rotationEffect(spin)
                .frame(width: 96, height: 96)

            Image(systemName: "bell.badge")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(Color.orange, Color.red)
        }
    }
}

struct Teardrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY + rect.height * 0.16),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.24),
            control2: CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.06),
            control2: CGPoint(x: rect.midX + rect.width * 0.24, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.16),
            control1: CGPoint(x: rect.midX - rect.width * 0.24, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.midY - rect.height * 0.08),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.24)
        )
        return path
    }
}

struct EyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.maxY),
            control2: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY)
        )
        return path
    }
}
