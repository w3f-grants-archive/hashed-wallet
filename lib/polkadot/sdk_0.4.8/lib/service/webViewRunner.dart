// ignore_for_file: always_put_control_body_on_new_line, prefer_const_constructors, prefer_final_in_for_each, missing_whitespace_between_adjacent_strings, unawaited_futures, duplicate_ignore

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hashed/polkadot/sdk_0.4.8/lib/api/types/networkParams.dart';
import 'package:hashed/polkadot/sdk_0.4.8/lib/service/keyring.dart';
import 'package:hashed/polkadot/sdk_0.4.8/lib/storage/keyring.dart';

extension PlatformExtension on Platform {
  static bool isIos14OrAbove() {
    if (Platform.isIOS) {
      final versionString = Platform.operatingSystemVersion;
      double? version;
      // iOS version string looks like this: "Version 15.5 (Build 0xFC10A)"
      versionString.split(" ").forEach((element) {
        version = version ?? double.tryParse(element);
      });
      //print("iOS version: $version");
      if (version != null) {
        return version! >= 14;
      } else {
        // cannot parse version string - must be > 15
        return true;
      }
    } else {
      return false;
    }
  }

  static bool canRunWasm() {
    if (Platform.isIOS) {
      return PlatformExtension.isIos14OrAbove();
    } else {
      return true;
    }
  }
}

class WebViewRunner {
  HeadlessInAppWebView? _web;
  Function? _onLaunched;

  late String _jsCode;
  Map<String, Function> _msgHandlers = {};
  Map<String, Completer> _msgCompleters = {};
  int _evalJavascriptUID = 0;

  bool webViewLoaded = false;
  int jsCodeStarted = -1;
  Timer? _webViewReloadTimer;

  // For direct JS execution - we don't get the wrapper here
  InAppWebViewController? get webViewController => _web?.webViewController;

  Future<void> launch(
    Function? onLaunched, {
    String? jsCode,
    Function? socketDisconnectedAction,
  }) async {
    // Get the operating system as a string.
    if (!PlatformExtension.canRunWasm()) {
      // TODO(n13): There's a way to make the API run without WASM
      throw Exception("This platform cannot run WASM code, polka API cannot run here");
    }

    /// reset state before webView launch or reload
    _msgHandlers = {};
    _msgCompleters = {};
    _evalJavascriptUID = 0;
    _onLaunched = onLaunched;
    webViewLoaded = false;
    jsCodeStarted = -1;

    _jsCode = jsCode ?? await rootBundle.loadString('assets/polkadot/sdk/js_api/dist/main.js');
    print('js file loaded ${_jsCode.length}');

    if (_web == null) {
      // await _startLocalServer();
      print("NOT starting web server since we already have inapp web server");
      final String homeUrl = "http://localhost:8080/assets/polkadot/sdk/assets/index.html";

      _web = HeadlessInAppWebView(
        // initialUrlRequest: URLRequest(url: Uri.parse(homeUrl)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(),
        ),
        onWebViewCreated: (controller) {
          print('HeadlessInAppWebView created!');
        },
        onConsoleMessage: (controller, message) {
          if (message.message.contains("API-WS: disconnected from")) {
            return;
          }
          if (message.message.contains("mnemonic")) {
            print("mnemonic console message hidden");
          } else {
            if (kDebugMode) {
              print("CONSOLE MESSAGE: ${message.message}");
            }
          }
          if (jsCodeStarted < 0) {
            if (message.message.contains('js loaded')) {
              jsCodeStarted = 1;
            } else {
              jsCodeStarted = 0;
            }
          }
          if (message.message.contains("WebSocket is not connected") && socketDisconnectedAction != null) {
            socketDisconnectedAction();
          }
          if (message.messageLevel != ConsoleMessageLevel.LOG) {
            return;
          }

          try {
            final msg = jsonDecode(message.message);

            final String? path = msg['path'];
            if (_msgCompleters[path!] != null) {
              final Completer handler = _msgCompleters[path]!;
              handler.complete(msg['data']);
              if (path.contains('uid=')) {
                _msgCompleters.remove(path);
              }
            }
            if (_msgHandlers[path] != null) {
              final Function handler = _msgHandlers[path]!;
              handler(msg['data']);
            }
          } catch (_) {
            // ignore
          }
        },
        onLoadStart: (controller, url) {
          print("onloadstart $url");
        },
        onLoadStop: (controller, url) async {
          print('webview loaded');
          if (webViewLoaded) {
            return;
          }

          _handleReloaded();
          await _startJSCode();
        },
      );

      await _web!.run();
      _web!.webViewController.loadUrl(urlRequest: URLRequest(url: Uri.parse(homeUrl)));
    } else {
      _webViewReloadTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        _tryReload();
      });
    }
  }

  void _tryReload() {
    if (!webViewLoaded) {
      _web?.webViewController.reload();
    }
  }

  Future<void> dispose() async {
    await _web?.dispose();
    _web = null;
  }

  void _handleReloaded() {
    _webViewReloadTimer?.cancel();
    webViewLoaded = true;
  }

  Future<void> _startJSCode() async {
    // inject js file to webView
    await _web!.webViewController.evaluateJavascript(source: _jsCode);

    _onLaunched!();
  }

  int getEvalJavascriptUID() {
    return _evalJavascriptUID++;
  }

  Future<dynamic> evalJavascript(
    String code, {
    bool wrapPromise = true,
    bool allowRepeat = true,
  }) async {
    // check if there's a same request loading
    if (!allowRepeat) {
      for (String i in _msgCompleters.keys) {
        final String call = code.split('(')[0];
        if (i.contains(call)) {
          print('request $call loading');
          return _msgCompleters[i]!.future;
        }
      }
    }

    if (!wrapPromise) {
      final res = await _web!.webViewController.evaluateJavascript(source: code);
      return res;
    }

    final c = Completer();

    final uid = getEvalJavascriptUID();
    final method = 'uid=$uid;${code.split('(')[0]}';
    _msgCompleters[method] = c;

    final script = '$code.then(function(res) {'
        '  console.log(JSON.stringify({ path: "$method", data: res }));res;'
        '}).catch(function(err) {'
        '  console.log(JSON.stringify({ path: "log", data: {call: "$method", error: err.message} }));'
        '  JSON.stringify({call: "$method", error: err.message });'
        '});';
    _web!.webViewController.evaluateJavascript(source: script);

    return c.future;
  }

  Future<NetworkParams?> connectNode(List<NetworkParams> nodes) async {
    final isAvatarSupport = (await evalJavascript('settings.connectAll ? {}:null', wrapPromise: false)) != null;
    final dynamic res = await (isAvatarSupport
        ? evalJavascript('settings.connectAll(${jsonEncode(nodes.map((e) => e.endpoint).toList())})')
        : evalJavascript('settings.connect(${jsonEncode(nodes.map((e) => e.endpoint).toList())})'));
    if (res != null) {
      final index = nodes.indexWhere((e) => e.endpoint!.trim() == res.trim());
      return nodes[index > -1 ? index : 0];
    }
    return null;
  }

  Future<void> subscribeMessage(
    String code,
    String channel,
    Function callback,
  ) async {
    addMsgHandler(channel, callback);
    evalJavascript(code);
  }

  void unsubscribeMessage(String channel) {
    print('unsubscribe $channel');
    final unsubCall = 'unsub$channel';
    _web!.webViewController.evaluateJavascript(source: 'window.$unsubCall && window.$unsubCall()');
  }

  void addMsgHandler(String channel, Function onMessage) {
    _msgHandlers[channel] = onMessage;
  }

  void removeMsgHandler(String channel) {
    _msgHandlers.remove(channel);
  }
}
