import Flutter
import UIKit

public class CupertinoNativeBetterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cupertino_native_better", binaryMessenger: registrar.messenger())
    let instance = CupertinoNativeBetterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Initialize transition observer early to setup edge gesture detection
    if #available(iOS 13.0, *) {
      _ = CNTransitionObserver.shared
    }

    // Setup native tab bar manager (runtime check inside)
    CNNativeTabBarManager.shared.setup(messenger: registrar.messenger())

    // Register platform view factories
    let sliderFactory = CupertinoSliderViewFactory(messenger: registrar.messenger())
    registrar.register(sliderFactory, withId: "CupertinoNativeBetterSlider")

    let switchFactory = CupertinoSwitchViewFactory(messenger: registrar.messenger())
    registrar.register(switchFactory, withId: "CupertinoNativeBetterSwitch")

    // Segmented control
    let segmentedFactory = CupertinoSegmentedControlViewFactory(messenger: registrar.messenger())
    registrar.register(segmentedFactory, withId: "CupertinoNativeBetterSegmentedControl")

    let iconFactory = CupertinoIconViewFactory(messenger: registrar.messenger())
    registrar.register(iconFactory, withId: "CupertinoNativeBetterIcon")

    let tabBarFactory = CupertinoTabBarViewFactory(messenger: registrar.messenger())
    registrar.register(tabBarFactory, withId: "CupertinoNativeBetterTabBar")

    let popupMenuFactory = CupertinoPopupMenuButtonViewFactory(messenger: registrar.messenger())
    registrar.register(popupMenuFactory, withId: "CupertinoNativeBetterPopupMenuButton")

    let buttonFactory = CupertinoButtonViewFactory(messenger: registrar.messenger())
    registrar.register(buttonFactory, withId: "CupertinoNativeBetterButton")
    
    let glassButtonGroupFactory = CupertinoGlassButtonGroupFactory(messenger: registrar.messenger())
    registrar.register(glassButtonGroupFactory, withId: "CupertinoNativeBetterGlassButtonGroup")
    
    let liquidGlassContainerFactory = LiquidGlassContainerFactory(messenger: registrar.messenger())
    registrar.register(liquidGlassContainerFactory, withId: "CupertinoNativeBetterLiquidGlassContainer")

    // Search bar
    let searchBarFactory = CupertinoSearchBarFactory(messenger: registrar.messenger())
    registrar.register(searchBarFactory, withId: "CNBetterSearchBar")

    // Floating island (Dynamic Island style)
    let floatingIslandFactory = FloatingIslandFactory(messenger: registrar.messenger())
    registrar.register(floatingIslandFactory, withId: "CNBetterFloatingIsland")

    // Search scaffold (UITabBarController with UISearchController for iOS 26+ liquid glass)
    // Factory is available on all iOS, runtime check happens inside
    let searchScaffoldFactory = CNSearchScaffoldViewFactory(messenger: registrar.messenger())
    registrar.register(searchScaffoldFactory, withId: "CNBetterSearchScaffold")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getMajorOSVersion":
      let version = ProcessInfo.processInfo.operatingSystemVersion
      result(Int(version.majorVersion))
    case "beginTransition":
      // Flutter is starting a navigation transition - disable glass effects temporarily
      if #available(iOS 13.0, *) {
        CNTransitionObserver.shared.beginTransition()
      }
      result(nil)
    case "endTransition":
      // Flutter navigation transition ended - re-enable glass effects
      if #available(iOS 13.0, *) {
        CNTransitionObserver.shared.endTransition()
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
 
