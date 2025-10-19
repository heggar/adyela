import 'package:hive/hive.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Abstract interface for auth local data source
abstract class AuthLocalDataSource {
  Future<void> cacheAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> clearAuthToken();

  Future<void> cacheRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> clearRefreshToken();

  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCachedUser();

  Future<void> clearAll();
}

/// Implementation of auth local data source using Hive
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<String> authBox;
  final Box userBox;

  AuthLocalDataSourceImpl({
    required this.authBox,
    required this.userBox,
  });

  @override
  Future<void> cacheAuthToken(String token) async {
    try {
      await authBox.put(AppConfig.authTokenKey, token);
    } catch (e) {
      throw CacheException('Failed to cache auth token: $e');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return authBox.get(AppConfig.authTokenKey);
    } catch (e) {
      throw CacheException('Failed to get auth token: $e');
    }
  }

  @override
  Future<void> clearAuthToken() async {
    try {
      await authBox.delete(AppConfig.authTokenKey);
    } catch (e) {
      throw CacheException('Failed to clear auth token: $e');
    }
  }

  @override
  Future<void> cacheRefreshToken(String token) async {
    try {
      await authBox.put(AppConfig.refreshTokenKey, token);
    } catch (e) {
      throw CacheException('Failed to cache refresh token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return authBox.get(AppConfig.refreshTokenKey);
    } catch (e) {
      throw CacheException('Failed to get refresh token: $e');
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      await authBox.delete(AppConfig.refreshTokenKey);
    } catch (e) {
      throw CacheException('Failed to clear refresh token: $e');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await userBox.put('current_user', user.toJson());
    } catch (e) {
      throw CacheException('Failed to cache user: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userData = userBox.get('current_user');
      if (userData != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData as Map));
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached user: $e');
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await userBox.delete('current_user');
    } catch (e) {
      throw CacheException('Failed to clear cached user: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await clearAuthToken();
      await clearRefreshToken();
      await clearCachedUser();
    } catch (e) {
      throw CacheException('Failed to clear all auth data: $e');
    }
  }
}
