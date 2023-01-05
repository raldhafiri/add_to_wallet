import Flutter
import PassKit
import UIKit

import Flutter
import UIKit

class PKAddPassButtonNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger, channel: FlutterMethodChannel) {
        self.messenger = messenger
        self.channel = channel
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PKAddPassButtonNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as! [String: Any],
            binaryMessenger: messenger,
            channel: channel)
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class PKAddPassButtonNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _width: CGFloat
    private var _height: CGFloat
    private var _key: String
    private var _channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: [String: Any],
        binaryMessenger messenger: FlutterBinaryMessenger?,
        channel: FlutterMethodChannel
    ) {
        _view = UIView()
        _width = args["width"] as? CGFloat ?? 140
        _height = args["height"] as? CGFloat ?? 30
        _key = args["key"] as! String
        _channel = channel
        super.init()
        createAddPassButton()
        addMethodHandler()
    }

    func view() -> UIView {
        _view
    }

    func createAddPassButton() {
        let passButton = PKAddPassButton(addPassButtonStyle: PKAddPassButtonStyle.black)
        passButton.frame = CGRect(x: 0, y: 0, width: _width, height: _height)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        _view.addSubview(passButton)
    }

    func addMethodHandler() {
        _channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterError(
                    code: "OBJECT_DEALLOCATED",
                    message: "The AddToWallet object was deallocated",
                    details: nil
                ))
                return
            }
            
            if call.method == AddToWalletEvent.addPassToWallet.rawValue {
                self.addToPass(call.arguments, result: result);
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc func passButtonAction() {
        _channel.invokeMethod(AddToWalletEvent.addButtonPressed.rawValue, arguments: ["key": _key])
    }

    func addToPass(_ callArguments: Any?, result: @escaping FlutterResult) {
        guard PKAddPassesViewController.canAddPasses() else {
            result(FlutterError(
                code: "ADD_TO_WALLET_NOT_SUPPORTED",
                message: "This device does not support Add to Wallet",
                details: nil
            ))
            return
        }
        
        guard let data = (callArguments as? FlutterStandardTypedData)?.data else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Expected type FlutterStandardDataType, got \(type(of: callArguments))",
                details: nil
            ))
            return
        }
        
        let newPass: PKPass
        
        do {
            newPass = try PKPass(data: data)
        } catch {
            result(FlutterError(
                code: "INVALID_DATA",
                message: error.localizedDescription,
                details: nil
            ))
            return
        }
        
        guard let addPassViewController = PKAddPassesViewController(pass: newPass) else {
            result(FlutterError(
                code: "UNABLE_TO_CREATE_ADD_TO_WALLET_VC",
                message: "Failed to create PKAddPassesViewController",
                details: nil
            ))
            return
        }
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(
                code: "UNABLE_TO_GET_ROOT_VC",
                message: "Unable to get View Controller for presentation",
                details: nil
            ))
            return
        }
        
        rootVC.present(addPassViewController, animated: true) {
            result(nil)
        }
    }
}

public class SwiftAddToWalletPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "add_to_wallet", binaryMessenger: registrar.messenger())
    let instance = SwiftAddToWalletPlugin()
    let factory = PKAddPassButtonNativeViewFactory(messenger: registrar.messenger(), channel: channel)
    registrar.register(factory, withId: "PKAddPassButton")
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        return result(FlutterMethodNotImplemented)
    }
}
