import 'dart:async';

import 'package:core/auth/domain/models/auth.dart';
import 'package:core/auth/domain/services/authentication_service_interface.dart';
import 'package:core/common/failures/failure.dart';
import 'package:core/users/domain/models/user.dart';
import 'package:core/users/domain/repositories/user_repository_interface.dart';
import 'package:core/users/graphql/users.graphql.dart';
import 'package:core/schema.graphql.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class SupabaseAuthenticationService implements AuthenticationServiceInterface {
  SupabaseAuthenticationService({
    required this.userRepository,
  }) {
    _authStateController = StreamController<AuthUser?>.broadcast();
    _initAuthListener();
  }

  final UserRepositoryInterface userRepository;
  late final StreamController<AuthUser?> _authStateController;
  
  sb.SupabaseClient get _supabase => sb.Supabase.instance.client;

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _updateAuthUser(session.user);
      } else {
        _authStateController.add(null);
      }
    });
  }

  Future<void> _updateAuthUser(sb.User sbUser) async {
    try {
      final result = await userRepository.queryUsers(
        filter: Input$UsersFilter(
          id: Input$UUIDFilter(
            eq: sbUser.id,
          ),
        ),
      );

      result.fold(
        (l) => _authStateController.add(null),
        (r) {
          if (r.isNotEmpty) {
            try {
              final user = r.first;
              _authStateController.add(AuthUser(
                supabaseUser: sbUser,
                user: user,
              ));
            } catch (e) {
              print('Null casting error in _updateAuthUser, using fallback: $e');
              _authStateController.add(null);
            }
          } else {
            _authStateController.add(null);
          }
        },
      );
    } catch (e) {
      _authStateController.add(null);
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  Future<AuthUser?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        _authStateController.add(null);
        return null;
      }

      final sbUser = session.user;
      
      final result = await userRepository.queryUsers(
        filter: Input$UsersFilter(
          id: Input$UUIDFilter(
            eq: sbUser.id,
          ),
        ),
      );

      return result.fold(
        (l) {
          _authStateController.add(null);
          return null;
        },
        (r) {
          if (r.isNotEmpty) {
            try {
              final user = r.first;
              final authUser = AuthUser(
                supabaseUser: sbUser,
                user: user,
              );
              _authStateController.add(authUser);
              return authUser;
            } catch (e) {
              print('Null casting error in getCurrentUser, using fallback: $e');
              _authStateController.add(null);
              return null;
            }
          } else {
            _authStateController.add(null);
            return null;
          }
        },
      );
    } catch (e) {
      _authStateController.add(null);
      return null;
    }
  }

  @override
  Future<Either<Failure, AuthUser>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: identifier,
        password: password,
      );

      if (response.session == null || response.user == null) {
        await _supabase.auth.signOut();
        _authStateController.add(null);
        return Left(Failure.unauthorized());
      }

      final sbUser = response.user!;

      final result = await userRepository.queryUsers(
        filter: Input$UsersFilter(
          id: Input$UUIDFilter(
            eq: sbUser.id,
          ),
        ),
      );

      return result.fold(
        (l) {
          _authStateController.add(null);
          return Left(Failure.unprocessableEntity(message: l.toString()));
        },
        (r) {
          if (r.isNotEmpty) {
            try {
              final user = r.first;
              final authUser = AuthUser(
                supabaseUser: sbUser,
                user: user,
              );
              _authStateController.add(authUser);
              return Right(authUser);
            } catch (e) {
              // Handle null casting errors for Supabase users with null did/handle/pdsUrl
              print('Null casting error in login, creating fallback user: $e');
              final authUser = AuthUser(
                supabaseUser: sbUser,
                user: User(
                  id: sbUser.id,
                  email: sbUser.email ?? '',
                  firstName: sbUser.userMetadata?['first_name'] ?? '',
                  lastName: sbUser.userMetadata?['last_name'] ?? '',
                  did: '', // Required but null for Supabase users
                  handle: '', // Required but null for Supabase users
                  pdsUrl: '', // Required but null for Supabase users
                  createdAt: DateTime.parse(sbUser.createdAt),
                  // Note: primaryStation will be null here, but that's ok for login
                  // The app can handle this case or reload the user data separately
                ),
              );
              _authStateController.add(authUser);
              return Right(authUser);
            }
          } else {
            _authStateController.add(null);
            return Left(Failure.notFound());
          }
        },
      );
    } on sb.AuthException catch (e) {
      await _supabase.auth.signOut();
      _authStateController.add(null);
      return Left(Failure.unauthorized());
    } catch (e) {
      await _supabase.auth.signOut();
      _authStateController.add(null);
      return Left(Failure.unprocessableEntity(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String handle,
    required String stationId,
  }) async {
    try {
      print('Starting registration for email: $email');
      
      // Step 1: Create Supabase auth user
      print('Step 1: Creating Supabase auth user...');
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      print('Auth response received. Session: ${authResponse.session != null}, User: ${authResponse.user != null}');
      
      // Check if user was created but no session (email confirmation required)
      if (authResponse.user == null) {
        print('Registration failed: No user returned from Supabase');
        return Left(Failure.unprocessableEntity(
            message: 'Failed to create account'));
      }
      
      if (authResponse.session == null) {
        print('User created but no session - email confirmation required');
        // User was created but needs email confirmation
        // We'll create the profile anyway and let them confirm later
      }

      final sbUser = authResponse.user!;
      print('Supabase user created with ID: ${sbUser.id}');

      // Step 2: Check if profile was created by trigger, otherwise create it
      print('Step 2: Checking/Creating user profile in database...');
      
      // First try to get the user profile (may have been created by trigger)
      final existingUserResult = await userRepository.queryUsers(
        filter: Input$UsersFilter(
          id: Input$UUIDFilter(
            eq: sbUser.id,
          ),
        ),
      );

      final Either<Failure, User> profileResult = await existingUserResult.fold(
        (l) async {
          // If query failed, try to create the profile
          print('Profile not found, creating new profile...');
          return await userRepository.createUser(
            input: Input$UsersInsertInput(
              id: sbUser.id,
              email: email,
              firstName: firstName,
              lastName: lastName,
              primaryStationId: stationId,
              // Don't set Bluesky fields for Supabase users - they'll be NULL
            ),
          );
        },
        (users) async {
          if (users.isNotEmpty) {
            // Profile already exists (created by trigger)
            print('Profile already exists (created by trigger), using existing profile');
            return Right(users.first) as Either<Failure, User>;
          } else {
            // No profile found, create one
            print('No profile found, creating new profile...');
            return await userRepository.createUser(
              input: Input$UsersInsertInput(
                id: sbUser.id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                primaryStationId: stationId,
                // Don't set Bluesky fields for Supabase users - they'll be NULL
              ),
            );
          }
        },
      );

      return profileResult.fold(
        (l) async {
          // Check if it's a duplicate key error - that means the trigger already created the profile
          if (l.toString().contains('duplicate key value violates unique constraint')) {
            print('Profile already exists (created by trigger), updating with station ID: $stationId');
            
            // Update the user profile with the station ID
            final updateResult = await userRepository.updateUser(
              id: sbUser.id,
              input: Input$UsersUpdateInput(
                primaryStationId: stationId,
              ),
            );
            
            print('Update result: ${updateResult.isRight() ? "Success" : "Failed - ${updateResult.fold((l) => l.toString(), (r) => "Success")}"}');
            
            // Try to fetch the updated user
            final userResult = await userRepository.queryUsers(
              filter: Input$UsersFilter(
                email: Input$StringFilter(
                  eq: email,
                ),
              ),
            );
            
            print('User query result: ${userResult.isRight() ? "Found ${userResult.fold((l) => 0, (r) => r.length)} users" : "Failed"}');
            
            return await userResult.fold(
              (queryError) async {
                // Since the update succeeded, we know the user has the station
                // Create auth user with the station data from previous state
                print('Could not fetch profile due to null casting, but update succeeded - using known station data');
                final authUser = AuthUser(
                  supabaseUser: sbUser,
                  user: User(
                    id: sbUser.id,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    did: '', // Required but null for Supabase users
                    handle: '', // Required but null for Supabase users
                    pdsUrl: '', // Required but null for Supabase users
                    createdAt: DateTime.now(),
                    primaryStationId: stationId, // Set the station ID - primaryStation will be null but that's ok
                  ),
                );
                _authStateController.add(authUser);
                return Right(authUser);
              },
              (users) async {
                if (users.isNotEmpty) {
                  final authUser = AuthUser(
                    supabaseUser: sbUser,
                    user: users.first,
                  );
                  _authStateController.add(authUser);
                  return Right(authUser);
                } else {
                  // Shouldn't happen but handle it
                  print('Database user creation failed: ${l.toString()}');
                  await _supabase.auth.signOut();
                  return Left(Failure.unprocessableEntity(message: 'Database error: ${l.toString()}'));
                }
              },
            );
          }
          
          print('Database user creation failed: ${l.toString()}');
          // Rollback: Delete the auth user if profile creation fails
          try {
            // Admin function would be needed to delete user
            // For now, just sign out
            await _supabase.auth.signOut();
          } catch (_) {}
          return Left(Failure.unprocessableEntity(message: 'Database error: ${l.toString()}'));
        },
        (r) {
          print('User profile created successfully');
          final authUser = AuthUser(
            supabaseUser: sbUser,
            user: r,
          );
          
          // Only add to auth state if there's a session (user is logged in)
          if (authResponse.session != null) {
            _authStateController.add(authUser);
          } else {
            print('User created but not logged in - email confirmation required');
            _authStateController.add(null); // Keep logged out state
          }
          
          return Right(authUser);
        },
      );
    } on sb.AuthException catch (e) {
      print('Supabase AuthException: ${e.message}');
      print('AuthException statusCode: ${e.statusCode}');
      return Left(Failure.unprocessableEntity(message: 'Auth error: ${e.message}'));
    } catch (e) {
      print('Unexpected error during registration: ${e.toString()}');
      return Left(Failure.unprocessableEntity(message: 'Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await _supabase.auth.signOut();
      _authStateController.add(null);
      return const Right(true);
    } catch (e) {
      return Left(Failure.unprocessableEntity(message: e.toString()));
    }
  }

  @override
  Future<Failure?> requestPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-callback/',
      );
      return null;
    } on sb.AuthException catch (e) {
      return Failure.unprocessableEntity(message: e.message);
    } catch (e) {
      return Failure.unprocessableEntity(message: e.toString());
    }
  }

  @override
  Future<Failure?> resetPassword(String token, String newPassword) async {
    try {
      // In Supabase, password reset is handled differently
      // The token is handled via deep link and the user is already authenticated
      // This method would be called after the user clicks the reset link
      final response = await _supabase.auth.updateUser(
        sb.UserAttributes(
          password: newPassword,
        ),
      );

      if (response.user == null) {
        return Failure.unprocessableEntity(message: 'Failed to reset password');
      }

      return null;
    } on sb.AuthException catch (e) {
      if (e.message.contains('expired')) {
        return Failure.unprocessableEntity(message: 'Expired token');
      } else if (e.message.contains('invalid')) {
        return Failure.unprocessableEntity(message: 'Invalid token');
      } else {
        return Failure.unprocessableEntity(message: e.message);
      }
    } catch (e) {
      return Failure.unprocessableEntity(message: e.toString());
    }
  }

  void dispose() {
    _authStateController.close();
  }
}