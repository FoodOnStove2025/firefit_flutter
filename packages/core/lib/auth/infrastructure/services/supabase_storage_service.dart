import 'package:core/auth/domain/services/storage_service_interface.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simplified storage service for Supabase
/// Supabase handles session persistence automatically, so this is mainly
/// for any additional app-specific data we want to store securely
class SupabaseStorageService implements StorageServiceInterface {
  final FlutterSecureStorage secureStorage;
  
  SupabaseStorageService(this.secureStorage);

  @override
  Future<void> saveSession(Map<String, dynamic> session) async {
    // Not needed for Supabase - it handles session persistence
    // Keep method for interface compatibility during migration
  }

  @override
  Future<Map<String, dynamic>?> getSession() async {
    // Not needed for Supabase - it handles session persistence
    // Return null to indicate no manual session storage
    return null;
  }

  @override
  Future<void> deleteSession() async {
    // Not needed for Supabase - it handles session persistence
    // Keep method for interface compatibility during migration
  }
  
  // Additional methods for storing app-specific data if needed
  Future<void> saveData(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }
  
  Future<String?> getData(String key) async {
    return await secureStorage.read(key: key);
  }
  
  Future<void> deleteData(String key) async {
    await secureStorage.delete(key: key);
  }
  
  Future<void> deleteAll() async {
    await secureStorage.deleteAll();
  }
}