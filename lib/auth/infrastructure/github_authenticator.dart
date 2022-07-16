import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/domain/auth_failure.dart';
import 'package:repo_viewer/auth/infrastructure/credential_storage/credential_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/shared/encoders.dart';
import '../../core/infrastructure/extension.dart';

class GithubOAuthHttpClient extends http.BaseClient {
  final httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}

class GithubAuthenticator {
  final CredentialStorage _credentialStorage;
  final Dio _dio;

  static final authorizationEndPoint =
      Uri.parse('https://github.com/login/oauth/authorize');
  static final tokenEndPoint =
      Uri.parse('https://github.com/login/oauth/access_token');

  static final redirectUrl = Uri.parse('http://localhost:3000/callback');
  static final revokationEndPoint =
      Uri.parse('https://api.github.com/applications/$cliendId/token');

  static const cliendId = 'ead8ff32aa2378d4c0db';
  static const clientSecret = '96b1f780e8f8858c2952f7fdd849fae638725a70';
  static const scopes = ['read:user', 'repo'];

  GithubAuthenticator(this._credentialStorage, this._dio);

  Future<Credentials?> getSignedInCredentials() async {
    try {
      final storedCredentials = await _credentialStorage.read();
      if (storedCredentials != null) {
        if (storedCredentials.canRefresh && storedCredentials.isExpired) {
          final failuerOrCredentials = await refresh(storedCredentials);
          return failuerOrCredentials.fold((l) => null, (r) => r);
        }
      }
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> isSignedIn() =>
      getSignedInCredentials().then((credentials) => credentials != null);

  AuthorizationCodeGrant createGrand() {
    return AuthorizationCodeGrant(
        cliendId, authorizationEndPoint, tokenEndPoint,
        secret: clientSecret);
  }

  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
  }

  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
    AuthorizationCodeGrant grant,
    Map<String, String> queryParams,
  ) async {
    try {
      final httpClient = await grant.handleAuthorizationResponse(queryParams);
      await _credentialStorage.save(httpClient.credentials);
      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}:${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    final accessToken = await _credentialStorage
        .read()
        .then((credentials) => credentials?.accessToken);

    final usernameAndPassword =
        stringToBase64.encode('$cliendId:$clientSecret');
    try {
      try {
        _dio.deleteUri(revokationEndPoint,
            data: {'access_token': accessToken},
            options: Options(
                headers: {'Authorization': 'basic $usernameAndPassword'}));
      } on DioError catch (e) {
        if (e.isConnectionError) {
          print('Token not revoked');
        } else {
          rethrow;
        }
      }
      await _credentialStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Credentials>> refresh(
    Credentials credentials,
  ) async {
    try {
      final refreshCredentials = await credentials.refresh(
          identifier: cliendId,
          secret: clientSecret,
          httpClient: GithubOAuthHttpClient());
      await _credentialStorage.save(refreshCredentials);
      return right(refreshCredentials);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error},${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}
