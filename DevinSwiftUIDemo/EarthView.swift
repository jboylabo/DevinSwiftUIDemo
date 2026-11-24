import SwiftUI

struct EarthView: View {
    private enum RotationSpeed: Double, CaseIterable, Identifiable {
        case slow = 0.5
        case normal = 1.0
        case fast = 2.0

        var id: Double { rawValue }

        var label: String {
            switch self {
            case .slow: "0.5x"
            case .normal: "1x"
            case .fast: "2x"
            }
        }
    }

    @State private var isPaused = false
    @State private var speed: RotationSpeed = .normal
    @State private var baseRotation: Double = 0.35
    @State private var accumulatedRotation: Double = 0.0
    @State private var lastTimestamp: TimeInterval?

    @State private var dragRotationOffset: Double = 0.0
    @State private var tilt: Double = 0.12
    @State private var dragTiltOffset: Double = 0.0

    var body: some View {
        TimelineView(.animation(paused: isPaused)) { timeline in
            let currentTime = timeline.date.timeIntervalSinceReferenceDate
            let liveRotation = rotationAngle(at: currentTime)
            let currentTilt = clampedTilt(tilt + dragTiltOffset)

            ZStack {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.black)
                        .colorEffect(
                            ShaderLibrary.earthShader(
                                .float2(proxy.size),
                                .float(Float(liveRotation)),
                                .float(Float(currentTilt)),
                                .float(Float(currentTime.truncatingRemainder(dividingBy: 10_000)))
                            )
                        )
                }
                .ignoresSafeArea()
                .gesture(rotationDragGesture)
                .onChange(of: timeline.date) { _, newDate in
                    advanceRotation(to: newDate.timeIntervalSinceReferenceDate)
                }

                VStack {
                    headerView
                    Spacer()
                    controlBar
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("EARTH")
                .font(.caption.weight(.semibold))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.72))
            Text("Metal Procedural Shader")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.top, 8)
    }

    private var controlBar: some View {
        HStack(spacing: 14) {
            Button {
                isPaused.toggle()
                if !isPaused {
                    lastTimestamp = nil
                }
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .accessibilityLabel(isPaused ? "回転を再開" : "回転を一時停止")

            HStack(spacing: 4) {
                ForEach(RotationSpeed.allCases) { option in
                    Button {
                        speed = option
                    } label: {
                        Text(option.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                speed == option ? Color.white.opacity(0.24) : Color.clear,
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(3)
            .background(.white.opacity(0.08), in: Capsule())

            Button {
                withAnimation(.easeOut(duration: 0.35)) {
                    tilt = 0.12
                    dragTiltOffset = 0.0
                    dragRotationOffset = 0.0
                    speed = .normal
                    isPaused = false
                    lastTimestamp = nil
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .accessibilityLabel("視点と速度をリセット")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var rotationDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragRotationOffset = Double(value.translation.width) * 0.012
                dragTiltOffset = Double(value.translation.height) * 0.008
            }
            .onEnded { value in
                baseRotation += Double(value.translation.width) * 0.012
                tilt = clampedTilt(tilt + Double(value.translation.height) * 0.008)
                dragRotationOffset = 0.0
                dragTiltOffset = 0.0
            }
    }

    private func advanceRotation(to timestamp: TimeInterval) {
        guard !isPaused else {
            lastTimestamp = timestamp
            return
        }
        if let previous = lastTimestamp {
            let dt = min(max(timestamp - previous, 0.0), 0.1)
            accumulatedRotation += dt * 0.42 * speed.rawValue
        }
        lastTimestamp = timestamp
    }

    private func rotationAngle(at timestamp: TimeInterval) -> Double {
        let pendingDelta: Double
        if !isPaused, let previous = lastTimestamp {
            let dt = min(max(timestamp - previous, 0.0), 0.1)
            pendingDelta = dt * 0.42 * speed.rawValue
        } else {
            pendingDelta = 0.0
        }
        return baseRotation + accumulatedRotation + pendingDelta + dragRotationOffset
    }

    private func clampedTilt(_ value: Double) -> Double {
        min(max(value, -1.1), 1.1)
    }
}

#Preview {
    EarthView()
        .preferredColorScheme(.dark)
}
