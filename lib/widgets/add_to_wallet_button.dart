import 'dart:async';

import 'package:add_to_wallet/add_to_wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class AddToWalletButton extends StatefulWidget {
  static const viewType = 'PKAddPassButton';

  final double width;
  final double height;
  final Widget? unsupportedPlatformChild;
  final FutureOr<List<int>> Function() onPressed;
  final String _id = Uuid().v4();

  AddToWalletButton(
      {Key? key,
      required this.width,
      required this.height,
      required this.onPressed,
      this.unsupportedPlatformChild})
      : super(key: key);

  @override
  _AddToWalletButtonState createState() => _AddToWalletButtonState();
}

class _AddToWalletButtonState extends State<AddToWalletButton> {
  get uiKitCreationParams => {
        'width': widget.width,
        'height': widget.height,
        'key': widget._id,
      };

  var _loading = false;

  @override
  void initState() {
    super.initState();
    AddToWallet().addHandler(widget._id, (_) async {
      setState(() {
        _loading = true;
      });
      final pkPass = await widget.onPressed();
      AddToWallet().addPassToWallet(pkPass);
      setState(() {
        _loading = false;
      });
    });
  }

  void dispose() {
    AddToWallet().removeHandler(widget._id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: platformWidget(context),
    );
  }

  Widget platformWidget(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _loading ? 1 : 0,
              child: CupertinoActivityIndicator(color: Colors.black),
            ),
            Opacity(
              opacity: _loading ? 0 : 1,
              child: UiKitView(
                viewType: AddToWalletButton.viewType,
                layoutDirection: Directionality.of(context),
                creationParams: uiKitCreationParams,
                creationParamsCodec: const StandardMessageCodec(),
              ),
            ),
          ],
        );

      default:
        if (widget.unsupportedPlatformChild == null)
          throw UnsupportedError('Unsupported platform view');
        return widget.unsupportedPlatformChild!;
    }
  }
}
