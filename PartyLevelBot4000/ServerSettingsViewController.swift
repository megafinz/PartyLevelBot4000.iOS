import Foundation
import RxSwift
import SocketIO
import UIKit

class ServerSettingsViewController: UIViewController {
    private enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }
    private var connectionState : ConnectionState = .disconnected
    private var socketManager : SocketManager!
    private var wsSub : Disposable!

    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var connectDisconnectButton: UIButton!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    @IBAction func onConnectDisconnect() {
        guard let host = hostTextField?.text, let port = portTextField?.text else {
            return
        }
        if self.connectionState == .disconnected {
            self.socketManager = SocketManager(socketURL: URL(string: "\(host):\(port)")!)
            let socket = self.socketManager.defaultSocket

            self.setConnectionStatus("Connecting…")
            self.setConnectionState(.connecting)

            socket.on(clientEvent: .connect) { _, _ in
                self.setConnectionStatus("Connected")
                self.setConnectionState(.connected)

                let engine = AudioEngine.sharedInstance()

                // Post amplitude.
                self.wsSub = Observable<Int>
                    .interval(1.0 / 10.0, scheduler: MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        socket.emit("amplitude in", String(format: "%.2f", engine.amplitude))
                    })
            }

            socket.on(clientEvent: .error) { reason, _ in
                self.wsSub?.dispose()
                self.setConnectionStatus("Disconnected: \(reason)")
                self.setConnectionState(.disconnected)
            }

            socket.on(clientEvent: .disconnect) { reason, _ in
                self.wsSub?.dispose()
                self.setConnectionStatus("Disconnected: \(reason)")
                self.setConnectionState(.disconnected)
            }

            socket.connect()
        } else {
            guard let sm = self.socketManager else {
                return;
            }
            sm.defaultSocket.disconnect()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }

    private func setConnectionState(_ value: ConnectionState) {
        guard let b = self.connectDisconnectButton else {
            return
        }

        self.connectionState = value

        switch value {
            case .connected, .connecting:
                b.setTitle("Disconnect", for: .normal)
            case .disconnected:
                b.setTitle("Connect", for: .normal)
        }
    }

    private func setConnectionStatus(_ text: String) {
        guard let cs = self.connectionStatusLabel else {
            return
        }
        cs.text = text
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
