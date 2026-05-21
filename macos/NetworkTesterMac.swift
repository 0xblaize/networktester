import SwiftUI
import Foundation

private let downloadURL = "https://speed.cloudflare.com/__down"
private let uploadURL = "https://speed.cloudflare.com/__up"

@main
struct NetworkTesterMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 780)
        }
    }
}

struct ContentView: View {
    @State private var speedValue = "0"
    @State private var speedUnit = "Mbps"
    @State private var speedLabel = "Click Start Test to begin"
    @State private var downloadResult = "-- Mbps"
    @State private var uploadResult = "-- Mbps"
    @State private var pingResult = "-- ms"
    @State private var progress = 0.0
    @State private var progressText = "Ready to test real internet speed"
    @State private var gaugeValue = 0.0
    @State private var isTesting = false
    @State private var websiteURL = "https://example.com"
    @State private var websiteResult = "Enter a website URL to test its response from this Mac."

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                speedometer
                metrics
                progressBlock
                buttons
                websiteBlock
                info
                Text("Built by Blaize")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.white)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Network Tester")
                .font(.system(size: 34, weight: .bold))
            Text("Real internet speed testing")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(red: 0.09, green: 0.15, blue: 0.20))
        .foregroundColor(.white)
    }

    private var speedometer: some View {
        VStack(spacing: 12) {
            GaugeView(value: gaugeValue)
                .frame(width: 340, height: 180)

            Text(speedValue)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.20))

            Text(speedUnit)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)

            Text(speedLabel)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: 430)
        .background(Color(red: 0.96, green: 0.98, blue: 0.99))
        .cornerRadius(12)
    }

    private var metrics: some View {
        HStack(spacing: 14) {
            MetricCard(title: "Download", value: downloadResult)
            MetricCard(title: "Upload", value: uploadResult)
            MetricCard(title: "Ping", value: pingResult)
        }
        .padding(.horizontal, 28)
    }

    private var progressBlock: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress, total: 100)
            Text(progressText)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 28)
    }

    private var buttons: some View {
        HStack(spacing: 14) {
            Button("START TEST") {
                Task { await startSpeedTest() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isTesting)

            Button("RESET") {
                resetTest()
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isTesting)
        }
        .padding(.horizontal, 28)
    }

    private var websiteBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Website Test")
                .font(.system(size: 18, weight: .bold))
            HStack {
                TextField("https://example.com", text: $websiteURL)
                    .textFieldStyle(.roundedBorder)
                Button("TEST WEBSITE") {
                    Task { await testWebsite() }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            Text(websiteResult)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(10)
        .padding(.horizontal, 28)
    }

    private var info: some View {
        Text("Download and upload tests send real data to Cloudflare speed test servers. Results depend on your ISP, Wi-Fi, firewall, and current network load.")
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .padding(.horizontal, 28)
    }

    private func startSpeedTest() async {
        if isTesting { return }
        isTesting = true
        resetTest()
        updateProgress(2, "Connecting to external speed test server...")

        do {
            let ping = try await measurePing()
            pingResult = "\(ping) ms"
            updateMain(value: Double(ping), label: "External Ping", unit: "ms", gauge: 0)

            updateProgress(20, "Testing real download speed...")
            let download = try await measureDownload()
            downloadResult = formatSpeed(download)
            updateMainSpeed(download, "Download Speed")

            updateProgress(62, "Testing real upload speed...")
            let upload = try await measureUpload()
            uploadResult = formatSpeed(upload)
            updateMainSpeed(upload, "Upload Speed")

            updateProgress(100, "Real internet speed test complete")
        } catch {
            updateProgress(0, "Error: \(error.localizedDescription)")
            updateMain(value: 0, label: "Error", unit: "Mbps", gauge: 0)
        }

        isTesting = false
    }

    private func measurePing() async throws -> Int {
        var samples: [Double] = []

        for _ in 0..<6 {
            let start = Date()
            let url = URL(string: "\(downloadURL)?bytes=0&r=\(UUID().uuidString)")!
            _ = try await URLSession.shared.data(from: url)
            samples.append(Date().timeIntervalSince(start) * 1000)
            try await Task.sleep(nanoseconds: 120_000_000)
        }

        samples.sort()
        let trimmed = Array(samples.dropFirst().dropLast())
        return Int((trimmed.reduce(0, +) / Double(trimmed.count)).rounded())
    }

    private func measureDownload() async throws -> Double {
        let sizes = [1, 5, 10, 25].map { $0 * 1024 * 1024 }
        let start = Date()
        var totalBytes = 0
        var speeds: [Double] = []
        var index = 0

        while Date().timeIntervalSince(start) < 12 {
            let size = sizes[min(index, sizes.count - 1)]
            let requestStart = Date()
            let url = URL(string: "\(downloadURL)?bytes=\(size)&r=\(UUID().uuidString)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            totalBytes += data.count
            let seconds = Date().timeIntervalSince(requestStart)
            if seconds > 0.15 {
                speeds.append(bytesToMbps(data.count, seconds))
            }

            let elapsed = Date().timeIntervalSince(start)
            let current = bytesToMbps(totalBytes, elapsed)
            updateMainSpeed(current, "Download Speed")
            updateProgress(20 + min(40, elapsed / 12 * 40), "Testing real download speed...")
            index += 1
        }

        if totalBytes == 0 { throw SpeedError.noData }
        return percentile(speeds.isEmpty ? [bytesToMbps(totalBytes, Date().timeIntervalSince(start))] : speeds, 0.8)
    }

    private func measureUpload() async throws -> Double {
        let sizes = [512 * 1024, 1024 * 1024, 5 * 1024 * 1024, 10 * 1024 * 1024]
        let start = Date()
        var totalBytes = 0
        var speeds: [Double] = []
        var index = 0

        while Date().timeIntervalSince(start) < 10 {
            let size = sizes[min(index, sizes.count - 1)]
            let body = Data(count: size)
            let url = URL(string: "\(uploadURL)?r=\(UUID().uuidString)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

            let requestStart = Date()
            _ = try await URLSession.shared.data(for: request)
            let seconds = Date().timeIntervalSince(requestStart)
            if seconds > 0.15 {
                speeds.append(bytesToMbps(size, seconds))
            }

            totalBytes += size
            let elapsed = Date().timeIntervalSince(start)
            let current = bytesToMbps(totalBytes, elapsed)
            updateMainSpeed(current, "Upload Speed")
            updateProgress(62 + min(36, elapsed / 10 * 36), "Testing real upload speed...")
            index += 1
        }

        if totalBytes == 0 { throw SpeedError.noData }
        return percentile(speeds.isEmpty ? [bytesToMbps(totalBytes, Date().timeIntervalSince(start))] : speeds, 0.8)
    }

    private func testWebsite() async {
        do {
            var value = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty {
                websiteResult = "Enter a website URL first."
                return
            }
            if !value.lowercased().hasPrefix("http://") && !value.lowercased().hasPrefix("https://") {
                value = "https://\(value)"
            }
            let url = URL(string: value)!
            let start = Date()
            let (data, response) = try await URLSession.shared.data(from: url)
            let total = Int((Date().timeIntervalSince(start) * 1000).rounded())
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            websiteResult = "Status \(code) | Total \(total) ms | Size \(formatBytes(data.count))"
        } catch {
            websiteResult = "Error: \(error.localizedDescription)"
        }
    }

    private func resetTest() {
        speedValue = "0"
        speedUnit = "Mbps"
        speedLabel = "Click Start Test to begin"
        downloadResult = "-- Mbps"
        uploadResult = "-- Mbps"
        pingResult = "-- ms"
        progress = 0
        progressText = "Ready to test real internet speed"
        gaugeValue = 0
    }

    private func updateProgress(_ value: Double, _ text: String) {
        progress = max(0, min(100, value))
        progressText = text
    }

    private func updateMain(value: Double, label: String, unit: String, gauge: Double) {
        speedValue = value >= 100 ? String(format: "%.0f", value) : String(format: "%.2f", value)
        speedUnit = unit
        speedLabel = label
        gaugeValue = gauge
    }

    private func updateMainSpeed(_ mbps: Double, _ label: String) {
        let display = speedDisplay(mbps)
        speedValue = display.value
        speedUnit = display.unit
        speedLabel = label
        gaugeValue = mbps
    }
}

struct GaugeView: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, 340)
            let height = geometry.size.height
            let normalized = log10(max(0, min(value, 1000)) + 1) / log10(1001)
            let angle = Angle.degrees(-120 + normalized * 240)

            ZStack(alignment: .bottom) {
                Arc(start: .degrees(180), end: .degrees(225))
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                Arc(start: .degrees(225), end: .degrees(270))
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                Arc(start: .degrees(270), end: .degrees(325))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                Arc(start: .degrees(325), end: .degrees(360))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 18, lineCap: .round))

                Rectangle()
                    .fill(Color(red: 0.09, green: 0.15, blue: 0.20))
                    .frame(width: width * 0.40, height: 5)
                    .offset(x: width * 0.20)
                    .rotationEffect(angle, anchor: .leading)
                    .animation(.easeOut(duration: 0.2), value: value)

                Circle()
                    .fill(Color(red: 0.09, green: 0.15, blue: 0.20))
                    .frame(width: 28, height: 28)
                    .offset(y: 14)

                HStack {
                    Text("0")
                    Spacer()
                    Text("100")
                    Spacer()
                    Text("500")
                    Spacer()
                    Text("1G")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .offset(y: -6)
            }
            .frame(width: width, height: height)
        }
    }
}

struct Arc: Shape {
    let start: Angle
    let end: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: min(rect.width / 2 - 18, rect.height - 18),
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        return path
    }
}

struct MetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.06, green: 0.54, blue: 0.37))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(10)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.93, green: 0.95, blue: 0.97))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

private enum SpeedError: Error {
    case noData
}

private func bytesToMbps(_ bytes: Int, _ seconds: Double) -> Double {
    if seconds <= 0 { return 0 }
    return Double(bytes) * 8 / 1024 / 1024 / seconds
}

private func percentile(_ values: [Double], _ p: Double) -> Double {
    if values.isEmpty { return 0 }
    let sorted = values.sorted()
    let index = max(0, min(sorted.count - 1, Int(ceil(Double(sorted.count) * p)) - 1))
    return sorted[index]
}

private func formatBytes(_ bytes: Int) -> String {
    if bytes < 1024 { return "\(bytes) B" }
    if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
    return String(format: "%.2f MB", Double(bytes) / 1024 / 1024)
}

private func formatSpeed(_ mbps: Double) -> String {
    let display = speedDisplay(mbps)
    return "\(display.value) \(display.unit)"
}

private func speedDisplay(_ mbps: Double) -> (value: String, unit: String) {
    if mbps > 0 && mbps < 1 {
        return (String(format: "%.0f", mbps * 1024), "Kbps")
    }
    return (mbps >= 100 ? String(format: "%.0f", mbps) : String(format: "%.2f", mbps), "Mbps")
}
