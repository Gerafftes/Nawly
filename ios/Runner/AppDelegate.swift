import CoreLocation
import Flutter
import Photos
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private let settingsPermissionCoordinator = SettingsPermissionCoordinator()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)

    guard let registrar = registry.registrar(forPlugin: "nawly/app_settings") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "nawly/app_settings",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.prepareAndOpenAppSettings(result: result)
    }
  }

  private func prepareAndOpenAppSettings(result: @escaping FlutterResult) {
    settingsPermissionCoordinator.prepareForAppSettingsPresentation { [weak self] in
      self?.openAppSettings(result: result)
    }
  }

  private func openAppSettings(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
        result(
          FlutterError(
            code: "invalid_url",
            message: "App settings URL could not be created.",
            details: nil
          )
        )
        return
      }

      guard UIApplication.shared.canOpenURL(settingsUrl) else {
        result(
          FlutterError(
            code: "unavailable",
            message: "App settings are not available.",
            details: nil
          )
        )
        return
      }

      UIApplication.shared.open(settingsUrl, options: [:]) { success in
        result(success)
      }
    }
  }
}

private final class SettingsPermissionCoordinator: NSObject, CLLocationManagerDelegate {
  private var completion: (() -> Void)?
  private var locationManager: CLLocationManager?

  func prepareForAppSettingsPresentation(completion: @escaping () -> Void) {
    self.completion = completion
    requestNotificationPermissionIfNeeded()
  }

  private func requestNotificationPermissionIfNeeded() {
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.getNotificationSettings { [weak self] settings in
      guard let self else {
        return
      }

      guard settings.authorizationStatus == .notDetermined else {
        self.requestPhotoPermissionIfNeeded()
        return
      }

      notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
        self.requestPhotoPermissionIfNeeded()
      }
    }
  }

  private func requestPhotoPermissionIfNeeded() {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      guard status == .notDetermined else {
        requestLocationPermissionIfNeeded()
        return
      }

      DispatchQueue.main.async {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] _ in
          self?.requestLocationPermissionIfNeeded()
        }
      }
      return
    }

    let legacyStatus = PHPhotoLibrary.authorizationStatus()
    guard legacyStatus == .notDetermined else {
      requestLocationPermissionIfNeeded()
      return
    }

    DispatchQueue.main.async {
      PHPhotoLibrary.requestAuthorization { [weak self] _ in
        self?.requestLocationPermissionIfNeeded()
      }
    }
  }

  private func requestLocationPermissionIfNeeded() {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }

      let locationManager = self.locationManager ?? CLLocationManager()
      guard locationManager.authorizationStatus == .notDetermined else {
        self.finish()
        return
      }

      locationManager.delegate = self
      self.locationManager = locationManager
      locationManager.requestWhenInUseAuthorization()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if currentAuthorizationStatus(for: manager) != .notDetermined {
      finish()
    }
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status != .notDetermined {
      finish()
    }
  }

  private func currentAuthorizationStatus(for manager: CLLocationManager) -> CLAuthorizationStatus {
    return manager.authorizationStatus
  }

  private func finish() {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }

      let completion = self.completion
      self.completion = nil
      self.locationManager = nil
      completion?()
    }
  }
}
