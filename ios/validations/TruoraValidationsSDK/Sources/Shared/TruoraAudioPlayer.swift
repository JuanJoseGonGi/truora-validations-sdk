//
//  TruoraAudioPlayer.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 04/03/26.
//

import AVFoundation
import Foundation

/// Audio instructions that can be played during document capture.
enum TruoraAudioInstruction: String {
    case placeTheFront = "place_the_front"
    case placeTheBack = "place_the_back"
    case rotateDocument = "rotate_document"
    case documentNotFound = "document_not_found"
}

/// Plays pre-recorded audio instructions during document capture.
/// Uses the SDK resource bundle (not Bundle.main) to locate MP3 files.
/// Audio playback is non-blocking and fails silently if files are missing.
///
/// Resolution order: audio_{lang}_{country}_{key} -> audio_{lang}_{key} -> audio_{lang}_{defaultCountry}_{key}.
final class TruoraAudioPlayer: NSObject, AVAudioPlayerDelegate {
    private static let defaultCountryForLanguage: [String: String] = [
        "es": "co"
    ]

    private let lock = NSLock()
    private var activePlayer: AVAudioPlayer?
    private var activeInstruction: TruoraAudioInstruction?
    private var playerCache: [TruoraAudioInstruction: AVAudioPlayer] = [:]
    private let languageCode: String
    private let countryCode: String

    init(languageCode: String, countryCode: String) {
        self.languageCode = languageCode.lowercased()
        self.countryCode = countryCode.lowercased()
        super.init()

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("TruoraAudioPlayer: Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    deinit {
        activePlayer?.stop()
        activePlayer = nil
    }

    /// Plays the given audio instruction.
    /// Tries language+country specific, then language-only fallback.
    func play(_ instruction: TruoraAudioInstruction) {
        lock.lock()
        defer { lock.unlock() }

        if activeInstruction == instruction, activePlayer?.isPlaying == true {
            return
        }

        stopLocked()

        if let cached = playerCache[instruction] {
            cached.currentTime = 0
            cached.play()
            activePlayer = cached
            activeInstruction = instruction
            return
        }

        guard let url = resolveAudioURL(for: instruction) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            playerCache[instruction] = player
            activePlayer = player
            activeInstruction = instruction
            player.play()
        } catch {
            print("TruoraAudioPlayer: Failed to play \(instruction.rawValue): \(error.localizedDescription)")
        }
    }

    /// Stops any currently playing audio.
    func stop() {
        lock.lock()
        defer { lock.unlock() }
        stopLocked()
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if activePlayer === player {
            activePlayer = nil
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        print("TruoraAudioPlayer: Decode error: \(error?.localizedDescription ?? "unknown")")
        lock.lock()
        defer { lock.unlock() }
        if activePlayer === player {
            activePlayer = nil
        }
    }

    // MARK: - Private

    private func stopLocked() {
        activePlayer?.stop()
        activePlayer = nil
        activeInstruction = nil
    }

    private func resolveAudioURL(for instruction: TruoraAudioInstruction) -> URL? {
        let key = instruction.rawValue

        // Try language + country: audio_{lang}_{country}_{key}
        if !countryCode.isEmpty {
            let countryFilename = "audio_\(languageCode)_\(countryCode)_\(key)"
            if let url = Bundle.truoraModule.url(forResource: countryFilename, withExtension: "mp3") {
                return url
            }
        }

        // Try language only: audio_{lang}_{key}
        let langFilename = "audio_\(languageCode)_\(key)"
        if let url = Bundle.truoraModule.url(forResource: langFilename, withExtension: "mp3") {
            return url
        }

        // Fall back to default country for this language: audio_{lang}_{defaultCountry}_{key}
        guard let defaultCountry = Self.defaultCountryForLanguage[languageCode],
              defaultCountry != countryCode else {
            return nil
        }
        let fallbackFilename = "audio_\(languageCode)_\(defaultCountry)_\(key)"
        return Bundle.truoraModule.url(forResource: fallbackFilename, withExtension: "mp3")
    }
}
