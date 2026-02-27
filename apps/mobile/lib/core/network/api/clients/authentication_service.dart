// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/o_auth_login_request.dart';
import '../models/refresh_token_request.dart';
import '../models/token_response.dart';

part 'authentication_service.g.dart';

@RestApi()
abstract class AuthenticationService {
  factory AuthenticationService(Dio dio, {String? baseUrl}) = _AuthenticationService;

  /// Login.
  ///
  /// OAuth login endpoint.
  ///
  /// Verify OAuth token, create/update user, and issue JWE tokens.
  @POST('/api/auth/login')
  Future<TokenResponse> loginApiAuthLoginPost({
    @Body() required OAuthLoginRequest body,
  });

  /// Refresh Token.
  ///
  /// Refresh access token using refresh token.
  @POST('/api/auth/refresh')
  Future<TokenResponse> refreshTokenApiAuthRefreshPost({
    @Body() required RefreshTokenRequest body,
  });

  /// Logout.
  ///
  /// Logout endpoint.
  ///
  /// Client should remove tokens from localStorage.
  @POST('/api/auth/logout')
  Future<void> logoutApiAuthLogoutPost();
}
