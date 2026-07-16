import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/user.dart';
import 'api_provider.dart';

class ProfileState {
  final AsyncValue<UserProfile?> profile;
  final bool isScanning;
  final String? scanError;

  ProfileState({
    required this.profile,
    this.isScanning = false,
    this.scanError,
  });

  ProfileState copyWith({
    AsyncValue<UserProfile?>? profile,
    bool? isScanning,
    String? scanError,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isScanning: isScanning ?? this.isScanning,
      scanError: scanError ?? this.scanError,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiService _apiService;

  ProfileNotifier(this._apiService)
      : super(ProfileState(profile: const AsyncValue.loading())) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(profile: const AsyncValue.loading());
    try {
      final p = await _apiService.fetchProfile();
      state = state.copyWith(profile: AsyncValue.data(p));
    } catch (e, st) {
      state = state.copyWith(profile: AsyncValue.error(e, st));
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = state.copyWith(profile: const AsyncValue.loading());
    try {
      final updated = await _apiService.saveProfile(profile);
      state = state.copyWith(profile: AsyncValue.data(updated));
    } catch (e, st) {
      state = state.copyWith(profile: AsyncValue.error(e, st));
    }
  }

  Future<bool> scanBiometrics({
    required UserProfile baseProfile,
    required XFile front,
    required XFile side,
    required XFile face,
  }) async {
    state = state.copyWith(isScanning: true, scanError: null);
    try {
      final scanned = await _apiService.analyzeProfilePhotos(
        frontPhoto: front,
        sidePhoto: side,
        facePhoto: face,
      );
      
      final mergedProfile = UserProfile(
        name: baseProfile.name,
        age: baseProfile.age,
        gender: baseProfile.gender,
        location: baseProfile.location,
        budget: baseProfile.budget,
        preferredStyle: baseProfile.preferredStyle,
        occupation: baseProfile.occupation,
        height: baseProfile.height,
        weight: baseProfile.weight,
        bodyType: scanned.bodyType,
        bodyBuild: scanned.bodyBuild,
        skinTone: scanned.skinTone,
        undertone: scanned.undertone,
        hairColor: scanned.hairColor,
        faceShape: scanned.faceShape,
        facialHair: scanned.facialHair,
        estimatedHeight: scanned.estimatedHeight,
      );

      final updatedProfile = await _apiService.saveProfile(mergedProfile);
      state = state.copyWith(
        profile: AsyncValue.data(updatedProfile),
        isScanning: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        scanError: e.toString(),
      );
      return false;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileNotifier(apiService);
});
