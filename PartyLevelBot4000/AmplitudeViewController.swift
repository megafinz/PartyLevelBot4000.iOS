import AudioKit
import RxSwift
import UIKit

class AmplitudeViewController: UIViewController {

    @IBOutlet weak var AmplitudeLabel: UILabel!
    @IBOutlet weak var AmplitudeProgressBar: UIProgressView!
    @IBOutlet weak var MaxAmplitudeLabel: UILabel!
    @IBOutlet weak var MaxAmplitudeProgressBar: UIProgressView!
    
    let db = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var maxAmplitude = 0.0

        let engine = AudioEngine.sharedInstance()

        do {
            try engine.start()

            // Current amplitude.
            Observable<Int>
                .interval(RxTimeInterval(1.0 / 60.0), scheduler: MainScheduler.instance)
                .subscribe(onNext: { _ in
                    guard
                        let al = self.AmplitudeLabel,
                        let apb = self.AmplitudeProgressBar,
                        let mal = self.MaxAmplitudeLabel,
                        let mapb = self.MaxAmplitudeProgressBar else {
                        return
                    }

                    al.text = String(format: "%.2f", engine.amplitude)
                    apb.progress = Float(engine.amplitude)

                    if (engine.amplitude > maxAmplitude) {
                        maxAmplitude = engine.amplitude
                        mal.text = String(format: "%.2f", maxAmplitude)
                        mapb.progress = Float(maxAmplitude)
                    }
                })
                .disposed(by: db)

            // Reset max amplitude.
            Observable<Int>
                .interval(3.0, scheduler: MainScheduler.instance)
                .subscribe(onNext: { _ in maxAmplitude = engine.amplitude })
                .disposed(by: db)
        } catch _ {
            print("FUCK")
        }
    }
}
