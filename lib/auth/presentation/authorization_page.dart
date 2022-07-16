import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthorizationPage extends StatefulWidget {
  final Uri authorizationUrl;
  final void Function(Uri redirectUrl) onAuthorizationRedirectAttempt;
  AuthorizationPage(
      {Key? key,
      required this.authorizationUrl,
      required this.onAuthorizationRedirectAttempt})
      : super(key: key);

  @override
  State<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends State<AuthorizationPage> {
  _AuthorizationPageState() : super();
  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: widget.authorizationUrl.toString(),
      javascriptMode: JavascriptMode.unrestricted,
    );
  }
}
