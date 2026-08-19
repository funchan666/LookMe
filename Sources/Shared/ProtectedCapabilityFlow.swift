import UIKit
import AVFoundation
import CoreLocation

enum LookMeProtectedCapability {
    case microphone
    case camera
    case location

    var title: String {
        switch self {
        case .microphone: return "Microphone unavailable"
        case .camera: return "Camera unavailable"
        case .location: return "Region tuning unavailable"
        }
    }

    var explanation: String {
        switch self {
        case .microphone: return "This action needs microphone access. You can continue using the rest of NightHub without it."
        case .camera: return "This action needs camera access. You can continue by choosing media from the picker instead."
        case .location: return "Current-region discovery needs location access. Manual region browsing remains available."
        }
    }
}

enum CallPermissionManager {
    static func request(video: Bool, from presenter: UIViewController, completion: @escaping () -> Void) {
        resolveCaptureAccess(.audio, capability: .microphone, from: presenter) { microphoneGranted in
            guard microphoneGranted else { return }
            guard video else { completion(); return }
            resolveCaptureAccess(.video, capability: .camera, from: presenter) { cameraGranted in
                if cameraGranted { completion() }
            }
        }
    }

    static func requestCameraCapture(videoIncludesAudio: Bool, from presenter: UIViewController, completion: @escaping () -> Void) {
        resolveCaptureAccess(.video, capability: .camera, from: presenter) { cameraGranted in
            guard cameraGranted else { return }
            guard videoIncludesAudio else { completion(); return }
            resolveCaptureAccess(.audio, capability: .microphone, from: presenter) { microphoneGranted in
                if microphoneGranted { completion() }
            }
        }
    }

    private static func resolveCaptureAccess(_ mediaType: AVMediaType, capability: LookMeProtectedCapability, from presenter: UIViewController, completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            DispatchQueue.main.async { completion(true) }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                // A first denial ends the action quietly. The system has already explained the choice.
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied:
            DispatchQueue.main.async {
                presenter.present(CapabilitySettingsViewController(capability: capability, settingsAvailable: true), animated: true)
                completion(false)
            }
        case .restricted:
            DispatchQueue.main.async {
                presenter.present(CapabilitySettingsViewController(capability: capability, settingsAvailable: false), animated: true)
                completion(false)
            }
        @unknown default:
            DispatchQueue.main.async { completion(false) }
        }
    }
}

final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    private let manager = CLLocationManager()
    private var authorizationCompletion: ((CLLocation?) -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestFromUserAction(from presenter: UIViewController, completion: @escaping (CLLocation?) -> Void) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationCompletion = completion
            manager.requestLocation()
        case .notDetermined:
            authorizationCompletion = completion
            manager.requestWhenInUseAuthorization()
        case .denied:
            presenter.present(CapabilitySettingsViewController(capability: .location, settingsAvailable: true), animated: true)
            completion(nil)
        case .restricted:
            presenter.present(CapabilitySettingsViewController(capability: .location, settingsAvailable: false), animated: true)
            completion(nil)
        @unknown default:
            completion(nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            // A first denial ends quietly; a settings option appears only on a later user action.
            authorizationCompletion?(nil)
            authorizationCompletion = nil
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        if let coordinate = location?.coordinate {
            UserDefaults.standard.set(coordinate.latitude, forKey: "regionalDiscoveryLatitude")
            UserDefaults.standard.set(coordinate.longitude, forKey: "regionalDiscoveryLongitude")
        }
        authorizationCompletion?(location)
        authorizationCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        authorizationCompletion?(nil)
        authorizationCompletion = nil
    }
}

final class CapabilitySettingsViewController: UIViewController {
    private let capability: LookMeProtectedCapability
    private let settingsAvailable: Bool

    init(capability: LookMeProtectedCapability, settingsAvailable: Bool) {
        self.capability = capability
        self.settingsAvailable = settingsAvailable
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.72)

        let card = UIView(); card.backgroundColor = LMTheme.panel; card.round(28); card.layer.borderWidth = 1; card.layer.borderColor = LMTheme.violet.withAlphaComponent(0.55).cgColor
        let orbit = UIImageView(image: UIImage(systemName: "hand.raised.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .semibold))); orbit.tintColor = LMTheme.pinkSoft; orbit.backgroundColor = LMTheme.violet.withAlphaComponent(0.22); orbit.contentMode = .center; orbit.round(28)
        let title = UILabel.lm(capability.title, size: 20, weight: .bold); title.font = LMTheme.displayFont(size: 20, weight: .bold); title.textAlignment = .center
        let note = UILabel.lm(capability.explanation, size: 13, weight: .medium, color: UIColor.white.withAlphaComponent(0.72)); note.numberOfLines = 0; note.textAlignment = .center
        let later = UIButton.lm("Not now"); later.backgroundColor = UIColor.white.withAlphaComponent(0.07); later.round(22); later.addTarget(self, action: #selector(close), for: .touchUpInside)
        let settings = UIButton.lm("Open Settings", symbol: "gearshape.fill"); settings.backgroundColor = LMTheme.pink; settings.round(22); settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside); settings.isHidden = !settingsAvailable
        let actions = UIStackView(arrangedSubviews: settingsAvailable ? [later, settings] : [later]); actions.axis = .horizontal; actions.distribution = .fillEqually; actions.spacing = 9

        [card, orbit, title, note, actions].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(card); [orbit, title, note, actions].forEach(card.addSubview)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28), card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28), card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            orbit.topAnchor.constraint(equalTo: card.topAnchor, constant: 25), orbit.centerXAnchor.constraint(equalTo: card.centerXAnchor), orbit.widthAnchor.constraint(equalToConstant: 56), orbit.heightAnchor.constraint(equalTo: orbit.widthAnchor),
            title.topAnchor.constraint(equalTo: orbit.bottomAnchor, constant: 17), title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18), title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 9), note.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24), note.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            actions.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 23), actions.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16), actions.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), actions.heightAnchor.constraint(equalToConstant: 46), actions.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    @objc private func close() { dismiss(animated: true) }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        dismiss(animated: true) { UIApplication.shared.open(url) }
    }
}
