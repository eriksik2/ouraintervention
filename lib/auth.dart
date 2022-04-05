import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:webview_flutter/webview_flutter.dart';

// These URLs are endpoints that are provided by the authorization
// server. They're usually included in the server's documentation of its
// OAuth2 API.
final authorizationEndpoint =
    Uri.parse('https://cloud.ouraring.com/oauth/authorize');
final tokenEndpoint = Uri.parse('https://api.ouraring.com/oauth/token');

// The authorization server will issue each client a separate client
// identifier and secret, which allows the server to tell which client
// is accessing it. Some servers may also have an anonymous
// identifier/secret pair that any client may use.
//
// Note that clients whose source code or binary executable is readily
// available may not be able to make sure the client secret is kept a
// secret. This is fine; OAuth2 servers generally won't rely on knowing
// with certainty that a client is who it claims to be.
final identifier = 'Q4EDXKDK2244IHFU';
final secret = 'VYOANLDLNJ473P6W7YAA2FRB6C4KRBXX';

// This is a URL on your application's server. The authorization server
// will redirect the resource owner here once they've authorized the
// client. The redirection will include the authorization code in the
// query parameters.
final redirectUrl = Uri.parse('wss://authresponse.ouraintervention.com');

/// A file in which the users credentials are stored persistently. If the server
/// issues a refresh token allowing the client to refresh outdated credentials,
/// these may be valid indefinitely, meaning the user never has to
/// re-authenticate.
final credentialsFile = File('~/.myapp/credentials.json');

class OAuth2InputForm extends StatefulWidget {
  const OAuth2InputForm({
    Key? key,
    required this.scopes,
    required this.state,
  }) : super(key: key);

  final List<String> scopes;
  final String state;

  @override
  _OAuth2InputFormState createState() => _OAuth2InputFormState();
}

class _OAuth2InputFormState extends State<OAuth2InputForm> {
  oauth2.AuthorizationCodeGrant? _grant;
  oauth2.Client? _client;

  @override
  void initState() {
    super.initState();
  }

  /// Either load an OAuth2 client from saved credentials or authenticate a new
  /// one.
  Future<void> getCredentials() async {
    // If the OAuth2 credentials have already been saved from a previous run, we
    // just want to reload them.
    if (await credentialsFile.exists()) {
      var credentials =
          oauth2.Credentials.fromJson(await credentialsFile.readAsString());
      var client =
          oauth2.Client(credentials, identifier: identifier, secret: secret);
      setState(() {
        _client = client;
        _grant = null;
      });
      return;
    }

    // If we don't have OAuth2 credentials yet, we need to get the resource owner
    // to authorize us. We're assuming here that we're a command-line application.
    var grant = oauth2.AuthorizationCodeGrant(
        identifier, authorizationEndpoint, tokenEndpoint,
        secret: secret);

    // A URL on the authorization server (authorizationEndpoint with some additional
    // query parameters). Scopes and state can optionally be passed into this method.
    //var authUri = grant.getAuthorizationUrl(redirectUrl, scopes: scopes, state: state);
    setState(() {
      _client = null;
      _grant = grant;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (_client != null) {
      return buildClient(context);
    }
    if (_grant != null) {
      return buildClientFromGrant(context);
    }
    getCredentials();
    return Column(
      children: const <Widget>[Text('Please wait...')],
    );
  }

  Widget buildClient(BuildContext context) {
    assert(_client != null);
    return Column(
      children: const <Widget>[Text('Please wait...')],
    );
  }

  Widget buildClientFromGrant(BuildContext context) {
    assert(_client == null && _grant != null);
    var grant = _grant!;
    var authorizationUrl = grant.getAuthorizationUrl(redirectUrl,
        scopes: widget.scopes, state: widget.state);
    return WebView(
      javascriptMode: JavascriptMode.unrestricted,
      initialUrl: authorizationUrl.toString(),
      navigationDelegate: (navReq) async {
        var responseUrl = Uri.parse(navReq.url);
        if (navReq.url.startsWith(redirectUrl.toString())) {
          var client = await grant
              .handleAuthorizationResponse(responseUrl.queryParameters);
          setState(() {
            _client = client;
          });
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      // ------- 8< -------
    );
  }
}
