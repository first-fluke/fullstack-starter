// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/api_auth_login_request_body_union.dart';
import '../models/refresh_token_request.dart';
import '../models/register_request.dart';
import '../models/session_exchange_request.dart';
import '../models/token_response.dart';
import '../models/user_response.dart';

part 'authentication_service.g.dart';

@RestApi()
abstract class AuthenticationService {
  factory AuthenticationService(Dio dio, {String? baseUrl}) =
      _AuthenticationService;

  /// Register.
  ///
  /// Register with email/password and issue backend tokens.
  @POST('/api/auth/register')
  Future<TokenResponse> registerApiAuthRegisterPost({
    @Body() required RegisterRequest body,
  });

  /// Login.
  ///
  /// Login with OAuth or email/password and issue backend tokens.
  ///
  /// Verify OAuth token, create/update user, and issue JWE tokens.
  @POST('/api/auth/login')
  Future<TokenResponse> loginApiAuthLoginPost({
    @Body() required ApiAuthLoginRequestBodyUnion body,
  });

  /// Session Exchange.
  ///
  /// Exchange better-auth session token for backend JWE tokens.
  ///
  /// Used by email/password auth users who have no OAuth provider token.
  /// Verifies session with better-auth server, then issues backend tokens.
  @POST('/api/auth/session-exchange')
  Future<TokenResponse> sessionExchangeApiAuthSessionExchangePost({
    @Body() required SessionExchangeRequest body,
  });

  /// Refresh Token.
  ///
  /// Refresh access token using refresh token (with rotation).
  @POST('/api/auth/refresh')
  Future<TokenResponse> refreshTokenApiAuthRefreshPost({
    @Body() required RefreshTokenRequest body,
  });

  /// Logout.
  ///
  /// Logout: revoke both the access token and the refresh token.
  @POST('/api/auth/logout')
  Future<void> logoutApiAuthLogoutPost({
    @Body() required RefreshTokenRequest body,
  });

  /// Get Me.
  ///
  /// Return the current authenticated user.
  @GET('/api/auth/me')
  Future<UserResponse> getMeApiAuthMeGet();
}
