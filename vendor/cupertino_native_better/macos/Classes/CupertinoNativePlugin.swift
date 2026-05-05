import Cocoa
import FlutterMacOS

public class CupertinoNativeBetterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cupertino_native_better", binaryMessenger: registrar.messenger)
    let instance = CupertinoNativeBetterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let sliderFactory = CupertinoSliderViewFactory(messenger: registrar.messenger)
    registrar.register(sliderFactory, withId: "CupertinoNativeBetterSlider")

    let switchFactory = CupertinoSwitchViewFactory(messenger: registrar.messenger)
    registrar.register(switchFactory, withId: "CupertinoNativeBetterSwitch")

    let segmentedFactory = CupertinoSegmentedControlViewFactory(messenger: registrar.messenger)
    registrar.register(segmentedFactory, withId: "CupertinoNativeBetterSegmentedControl")

    let iconFactory = CupertinoIconViewFactory(messenger: registrar.messenger)
    registrar.register(iconFactory, withId: "CupertinoNativeBetterIcon")

    let tabBarFactory = CupertinoTabBarViewFactory(messenger: registrar.messenger)
    registrar.register(tabBarFactory, withId: "CupertinoNativeBetterTabBar")

    let popupMenuFactory = CupertinoPopupMenuButtonViewFactory(messenger: registrar.messenger)
    registrar.register(popupMenuFactory, withId: "CupertinoNativeBetterPopupMenuButton")

    let buttonFactory = CupertinoButtonViewFactory(messenger: registrar.messenger)
    registrar.register(buttonFactory, withId: "CupertinoNativeBetterButton")
    
    let liquidGlassContainerFactory = LiquidGlassContainerFactory(messenger: registrar.messenger)
    registrar.register(liquidGlassContainerFactory, withId: "CupertinoNativeBetterLiquidGlassContainer")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getMajorOSVersion":
      let version = ProcessInfo.processInfo.operatingSystemVersion
      result(Int(version.majorVersion))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
