# Supabase Authentication Migration Guide

## Overview
This document outlines the migration from Bluesky authentication to Supabase Auth in the FireFit Flutter application.

## Migration Status
The application now supports **both** Bluesky and Supabase authentication. You can toggle between them using the `useSupabaseAuth` flag in `/lib/features/auth/providers/authentication_service_provider.dart`.

## What Changed

### 1. New Authentication Service
- **File**: `packages/core/lib/auth/infrastructure/services/supabase_authentication_service.dart`
- Implements the same `AuthenticationServiceInterface` as Bluesky
- Uses Supabase's built-in auth methods
- Automatically handles session refresh

### 2. Updated Auth Models
- **File**: `packages/core/lib/auth/domain/models/auth.dart`
- `AuthUser` now supports both Bluesky and Supabase user types
- Legacy Bluesky fields are optional for backward compatibility
- Helper getters provide unified access to user data

### 3. New UI Screens
- **Supabase Login**: `lib/features/auth/presentation/screens/supabase_login_screen.dart`
- **Supabase Registration**: `lib/features/auth/presentation/screens/supabase_registration_screen.dart`
- Simplified forms without Bluesky-specific fields (PDS server, handle)

### 4. Database Schema Updates
- **Migration**: `supabase/migrations/20240101_migrate_to_supabase_auth.sql`
- Makes Bluesky fields (did, handle, pdsUrl) nullable
- Adds foreign key to Supabase auth.users table
- Includes RLS policies for secure access

## How to Enable Supabase Auth

1. **Toggle the Auth Provider**:
   ```dart
   // In authentication_service_provider.dart
   const bool useSupabaseAuth = true; // Set to true for Supabase
   ```

2. **Run Database Migration**:
   ```bash
   supabase db push
   # Or manually run the migration file in your Supabase dashboard
   ```

3. **Configure Supabase**:
   - Ensure your `.env` file has correct Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_anon_key
     ```

## Features Comparison

| Feature | Bluesky | Supabase |
|---------|---------|----------|
| Email/Password Login | ✅ | ✅ |
| Registration | ✅ | ✅ |
| Password Reset | ✅ | ✅ |
| Session Management | Manual | Automatic |
| Social Features | ✅ | ❌ |
| Email Verification | ❌ | ✅ |
| OAuth Providers | ❌ | ✅ (configurable) |

## Testing

1. **Test Supabase Registration**:
   - Navigate to `/register`
   - Fill in the form (no handle required)
   - Check email for verification link

2. **Test Supabase Login**:
   - Navigate to `/login`
   - Use email and password only
   - Should redirect to home on success

3. **Test Password Reset**:
   - Click "Forgot password?" on login screen
   - Enter email
   - Check email for reset link

## Rollback Plan

To rollback to Bluesky auth:
1. Set `useSupabaseAuth = false` in `authentication_service_provider.dart`
2. Rebuild and deploy the app

## Future Considerations

1. **Data Migration**: Consider migrating existing Bluesky users to Supabase
2. **Social Features**: Implement alternative social features or remove feed functionality
3. **Cleanup**: Once stable, remove Bluesky dependencies and code
4. **OAuth**: Add social login providers through Supabase (Google, Apple, etc.)

## Troubleshooting

### Common Issues

1. **"User profile not found" error**:
   - Ensure the database trigger is created (Step 6-7 in migration)
   - Check that Users table has proper permissions

2. **Session not persisting**:
   - Verify Supabase is initialized in `main.dart`
   - Check that deep links are configured for password reset

3. **Registration fails**:
   - Verify station code is valid
   - Check Supabase email settings are configured

## Support

For issues or questions about the migration, please check:
- Supabase Auth documentation: https://supabase.com/docs/guides/auth
- Flutter Supabase package: https://pub.dev/packages/supabase_flutter