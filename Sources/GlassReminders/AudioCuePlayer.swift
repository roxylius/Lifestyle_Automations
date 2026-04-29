import AppKit
import AVFoundation
import GlassRemindersCore

final class AudioCuePlayer: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var systemSound: NSSound?

    func play(for job: ReminderJob) {
        playSound(for: job)
        speak(job.speechText, volume: job.volume)
    }

    private func playSound(for job: ReminderJob) {
        if let path = job.asset.customSoundPath, !path.isEmpty {
            do {
                let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                player.volume = Float(job.volume)
                player.prepareToPlay()
                player.play()
                audioPlayer = player
                return
            } catch {
                NSLog("GlassReminders: failed to play custom sound: \(error)")
            }
        }

        let fallbackName: NSSound.Name = job.asset.style == .water ? .init("Glass") : .init("Ping")
        guard let sound = NSSound(named: fallbackName) else {
            return
        }
        sound.volume = Float(job.volume)
        sound.play()
        systemSound = sound
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
