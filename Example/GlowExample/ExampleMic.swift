import AVFoundation
import Combine
import Foundation

/// Local meter for the example app. Not part of the package.
/// The audio dies here. Apps that use the glow measure their own level
/// and pass a number from 0 to 1.
@MainActor
final class ExampleMic: ObservableObject {
    @Published var level: Double = 0
    @Published var isLive = false
    @Published var error: String?
    @Published var input = ""

    private var audio: AVAudioEngine?
    private var sessionGeneration = 0

    func toggle() {
        isLive ? stop() : start()
    }

    func start() {
        error = nil
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted {
                    self.open()
                } else {
                    self.error = "Microphone blocked. Allow it in Settings > Privacy > Microphone."
                }
            }
        }
    }

    func stop() {
        tearDown()
        sessionGeneration += 1
        let token = sessionGeneration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard token == self.sessionGeneration, self.audio == nil else { return }
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    private func open() {
        sessionGeneration += 1
        tearDown()
        let session = AVAudioSession.sharedInstance()
        do {
            #if targetEnvironment(simulator)
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            #else
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            #endif
            if let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                try? session.setPreferredInput(builtIn)
            }
            try session.setActive(true)
        } catch {
            self.error = error.localizedDescription
            return
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        engine.prepare()
        do {
            try engine.start()
        } catch {
            self.error = error.localizedDescription
            return
        }

        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            engine.stop()
            self.error = "No microphone on this route."
            return
        }
        self.input = "\(format.channelCount)ch @ \(Int(format.sampleRate))Hz"

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            let heard = ExampleMic.rms(buffer)
            Task { @MainActor in
                self?.level = heard
            }
        }
        audio = engine
        isLive = true
    }

    private func tearDown() {
        if let audio {
            audio.inputNode.removeTap(onBus: 0)
            audio.stop()
            audio.reset()
        }
        audio = nil
        isLive = false
        level = 0
    }

    nonisolated static func rms(_ buffer: AVAudioPCMBuffer) -> Double {
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }
        var sum = 0.0
        if let channel = buffer.floatChannelData?[0] {
            for i in 0..<frames {
                let sample = Double(channel[i])
                sum += sample * sample
            }
        } else if let channel = buffer.int16ChannelData?[0] {
            for i in 0..<frames {
                let sample = Double(channel[i]) / Double(Int16.max)
                sum += sample * sample
            }
        } else {
            return 0
        }
        return min(1, sqrt(sum / Double(frames)) * 6)
    }
}
