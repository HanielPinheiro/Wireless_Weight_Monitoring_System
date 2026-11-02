import UIKit
import Flutter
import CoreBluetooth

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?
    var eventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

        let methodChannel = FlutterMethodChannel(name: "bluetooth_helper", binaryMessenger: controller.binaryMessenger)
        let eventChannel = FlutterEventChannel(name: "bluetooth_helper_state", binaryMessenger: controller.binaryMessenger)

        methodChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "isBluetoothOn" {
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    result(self.centralManager?.state == .poweredOn)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        eventChannel.setStreamHandler(self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        eventSink?(central.state == .poweredOn)
    }
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
