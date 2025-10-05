import 'package:atproto/core.dart' as atproto;
import 'package:core/users/domain/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// A more complete replacement for ProfileViewDetailed with all required properties
class ProfileView {
  final String? displayName;
  final String? description;
  final String? avatar; // Added for UI components that use profile.avatar
  final String? handle; // Added for UI components that use profile.handle

  ProfileView({
    this.displayName,
    this.description,
    this.avatar,
    this.handle,
  });

  // Factory to convert from the original bluesky ProfileViewDetailed
  factory ProfileView.fromBluesky(dynamic original) {
    try {
      // Try to access the properties regardless of type
      return ProfileView(
        displayName: original.displayName,
        description: original.description,
        avatar: original.avatar,
        handle: original.handle,
      );
    } catch (e) {
      // If any error occurs, return a default ProfileView
      return ProfileView();
    }
  }
}

class AuthUser {
  // Legacy Bluesky fields (optional, for backward compatibility during migration)
  final atproto.Session? session;
  final ProfileView? profile;
  final String? service;
  
  // New Supabase fields
  final sb.User? supabaseUser;
  
  // Common field
  final User user;

  AuthUser({
    this.session,
    this.profile,
    this.service,
    this.supabaseUser,
    required this.user,
  });
  
  // Helper getters for compatibility
  String get email => supabaseUser?.email ?? user.email ?? '';
  String get displayName {
    if (profile?.displayName != null) return profile!.displayName!;
    final firstName = user.firstName ?? '';
    final lastName = user.lastName ?? '';
    return '$firstName $lastName'.trim();
  }
  String? get avatarUrl => profile?.avatar ?? supabaseUser?.userMetadata?['avatar_url'];
  String get userId => supabaseUser?.id ?? session?.did ?? user.id;
}
