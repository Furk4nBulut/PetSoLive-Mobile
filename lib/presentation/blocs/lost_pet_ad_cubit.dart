import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/lost_pet_ad_dto.dart';
import '../../domain/repositories/lost_pet_ad_repository.dart';

abstract class LostPetAdState {}
class LostPetAdInitial extends LostPetAdState {}
class LostPetAdLoading extends LostPetAdState {}
class LostPetAdLoaded extends LostPetAdState {
  final List<LostPetAdDto> ads;
  final bool hasMore;
  LostPetAdLoaded(this.ads, {required this.hasMore});
}
class LostPetAdDetailLoaded extends LostPetAdState {
  final LostPetAdDto? ad;
  LostPetAdDetailLoaded(this.ad);
}
class LostPetAdError extends LostPetAdState {
  final String error;
  LostPetAdError(this.error);
}

class LostPetAdCubit extends Cubit<LostPetAdState> {
  final LostPetAdRepository repository;
  LostPetAdCubit(this.repository) : super(LostPetAdInitial());

  Future<void> getAll() async {
    if (isClosed) return;
    emit(LostPetAdLoading());
    try {
      final list = await repository.getAll();
      final sortedAds = List<LostPetAdDto>.from(list)
        ..sort((a, b) => b.id.compareTo(a.id));
      if (isClosed) return;
      emit(LostPetAdLoaded(sortedAds, hasMore: false));
    } catch (e) {
      if (isClosed) return;
      emit(LostPetAdError(e.toString()));
    }
  }

  Future<void> getById(int id) async {
    if (isClosed) return;
    emit(LostPetAdLoading());
    try {
      final ad = await repository.getById(id);
      if (isClosed) return;
      emit(LostPetAdDetailLoaded(ad));
    } catch (e) {
      if (isClosed) return;
      emit(LostPetAdError(e.toString()));
    }
  }

  Future<void> create(LostPetAdDto dto, String token) async {
    if (isClosed) return;
    emit(LostPetAdLoading());
    try {
      await repository.create(dto, token);
      if (isClosed) return;
      await getAll();
    } catch (e) {
      if (isClosed) return;
      emit(LostPetAdError(e.toString()));
    }
  }

  Future<void> update(int id, LostPetAdDto dto, String token) async {
    if (isClosed) return;
    emit(LostPetAdLoading());
    try {
      await repository.update(id, dto, token);
      if (isClosed) return;
      emit(LostPetAdInitial());
    } catch (e) {
      if (isClosed) return;
      emit(LostPetAdError(e.toString()));
    }
  }

  Future<void> delete(int id, String token) async {
    if (isClosed) return;
    emit(LostPetAdLoading());
    try {
      await repository.delete(id, token);
      if (isClosed) return;
      emit(LostPetAdInitial());
    } catch (e) {
      if (isClosed) return;
      emit(LostPetAdError(e.toString()));
    }
  }
} 