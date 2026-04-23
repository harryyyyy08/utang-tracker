import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<ProfileModel?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return data != null ? ProfileModel.fromJson(data) : null;
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', userId);
  }
}
