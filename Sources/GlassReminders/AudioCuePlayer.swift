import AppKit
import AVFoundation
import GlassRemindersCore

final class AudioCuePlayer: NSObject {
    private enum SoundRequest {
        case custom(URL, Float)
        case system(NSSound.Name, Float)
    }

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var systemSound: NSSound?
    private var repeatTimer: Timer?
    private var repeatRequest: SoundRequest?
    private var remainingRepeatCount = 0
    private var repeatGap: TimeInterval = 1.5

    func play(for job: ReminderJob) {
        stop()
        playSound(for: job)
        speak(job.speechText, volume: job.volume)
    }

    func stop() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        repeatRequest = nil
        remainingRepeatCount = 0

        audioPlayer?.stop()
        audioPlayer = nil

        systemSound?.stop()
        systemSound = nil

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func playSound(for job: ReminderJob) {
        if let path = job.asset.customSoundPath, !path.isEmpty {
            let request = SoundRequest.custom(URL(fileURLWithPath: path), Float(job.volume))
            if play(request, mode: job.audioPlaybackMode, repeatCount: job.audioRepeatCount, gap: job.audioRepeatGapSeconds) {
                return
            }
        }

        let fallbackName: NSSound.Name = job.asset.style == .water ? .init("Glass") : .init("Ping")
        _ = play(
            .system(fallbackName, Float(job.volume)),
            mode: job.audioPlaybackMode,
            repeatCount: job.audioRepeatCount,
            gap: job.audioRepeatGapSeconds
        )
    }

    private func play(
        _ request: SoundRequest,
        mode: AudioPlaybackMode,
        repeatCount: Int,
        gap: Double
    ) -> Bool {
        switch mode {
        case .loopUntilAction:
            return playLooping(request)
        case .repeatCount:
            return playFiniteRepeats(request, repeatCount: repeatCount, gap: gap)
        }
    }

    private func playLooping(_ request: SoundRequest) -> Bool {
        switch request {
        case .custom(let url, let volume):
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.numberOfLoops = -1
                player.prepareToPlay()
                player.play()
                audioPlayer = player
                return true
            } catch {
                NSLog("GlassReminders: failed to loop custom sound: \(error)")
                return false
            }

        case .system(let name, let volume):
            guard let sound = NSSound(named: name) else {
                return false
            }
            sound.volume = volume
            sound.loops = true
            sound.play()
            systemSound = sound
            return true
        }
    }

    private func playFiniteRepeats(_ request: SoundRequest, repeatCount: Int, gap: Double) -> Bool {
        repeatRequest = request
        remainingRepeatCount = max(repeatCount, 1)
        repeatGap = TimeInterval(max(gap, 0))
        return playNextRepeat()
    }

    @discardableResult
    private func playNextRepeat() -> Bool {
        guard remainingRepeatCount > 0, let request = repeatRequest else {
            return false
        }

        remainingRepeatCount -= 1
        let duration = playOnce(request)
        guard duration > 0 else {
            self.repeatRequest = nil
            remainingRepeatCount = 0
            return false
        }

        if remainingRepeatCount > 0 {
            repeatTimer = Timer.scheduledTimer(withTimeInterval: max(duration + repeatGap, 0.1), repeats: false) { [weak self] _ in
                self?.playNextRepeat()
            }
        }

        return true
    }

    private func playOnce(_ request: SoundRequest) -> TimeInterval {
        audioPlayer?.stop()
        systemSound?.stop()

        switch request {
        case .custom(let url, let volume):
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.numberOfLoops = 0
                player.prepareToPlay()
                player.play()
                audioPlayer = player
                return max(player.duration, 0.25)
            } catch {
                NSLog("GlassReminders: failed to play custom sound: \(error)")
                return 0
            }

        case .system(let name, let volume):
            guard let sound = NSSound(named: name) else {
                return 0
            }
            sound.volume = volume
            sound.loops = false
            sound.play()
            systemSound = sound
            return max(sound.duration, 0.5)
        }
    }

    private func speak(_ text: String, volume: Double) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return
        }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.volume = Float(min(max(volume, 0), 1))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}
