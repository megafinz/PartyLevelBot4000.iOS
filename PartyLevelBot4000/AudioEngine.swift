import AudioKit
import Foundation

class AudioEngine {

    private static var instance : AudioEngine = AudioEngine()

    private let mic : AKMicrophone
    private let tracker : AKAmplitudeTracker
    private let silence : AKBooster

    init() {
        self.mic = AKMicrophone()
        self.tracker = AKAmplitudeTracker(mic)
        self.silence = AKBooster(tracker, gain: 0)
        AudioKit.output = self.silence
    }

    var amplitude : Double {
        get { return self.tracker.amplitude }
    }

    func start() throws {
        try AudioKit.start()
    }

    static func sharedInstance() -> AudioEngine {
        return instance
    }
}
