import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/pet_dto.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../data/providers/pet_owner_api_service.dart';

abstract class PetState {}
class PetInitial extends PetState {}
class PetLoading extends PetState {}
class PetLoaded extends PetState {
  final List<PetDto> allPets;
  final List<PetDto> myPets;
  PetLoaded({required this.allPets, required this.myPets});
}
class PetDetailLoaded extends PetState {
  final PetDto? pet;
  PetDetailLoaded(this.pet);
}
class PetError extends PetState {
  final String error;
  PetError(this.error);
}
class PetFiltered extends PetState {
  final List<PetDto> pets;
  PetFiltered(this.pets);
}

class PetCubit extends Cubit<PetState> {
  final PetRepository repository;
  List<PetDto> _allPets = [];
  PetOwnerApiService? petOwnerApiService;
  int? currentUserId;
  PetCubit(this.repository) : super(PetInitial());

  @override
  Future<void> getAll() async {
    emit(PetLoading());
    try {
      final list = await repository.getAll();
      _allPets = list;
      if (!isClosed) emit(PetLoaded(allPets: list, myPets: []));
    } catch (e) {
      if (!isClosed) emit(PetError(e.toString()));
    }
  }

  Future<void> getAllWithOwners({required int? userId, required PetOwnerApiService petOwnerApiService}) async {
    emit(PetLoading());
    try {
      final list = await repository.getAll();
      final petsWithOwner = (await Future.wait(list.map((pet) async {
        final owner = await petOwnerApiService.getByPetId(pet.id);
        return pet.copyWith(ownerId: owner?.userId);
      }))).cast<PetDto>();
      final myPets = userId == null ? <PetDto>[] : petsWithOwner.where((pet) => pet.ownerId == userId).toList();
      if (!isClosed) emit(PetLoaded(allPets: petsWithOwner, myPets: myPets));
    } catch (e) {
      if (!isClosed) emit(PetError(e.toString()));
    }
  }

  void filterPets(String query) {
    if (state is PetLoaded || state is PetFiltered) {
      final filtered = _allPets.where((pet) {
        final lower = query.toLowerCase();
        return pet.name.toLowerCase().contains(lower) ||
               pet.species.toLowerCase().contains(lower) ||
               (pet.breed?.toLowerCase().contains(lower) ?? false);
      }).toList();
      if (!isClosed) emit(PetFiltered(filtered));
    }
  }

  Future<void> getById(int id) async {
    emit(PetLoading());
    try {
      final pet = await repository.getById(id);
      if (!isClosed) emit(PetDetailLoaded(pet));
    } catch (e) {
      if (!isClosed) emit(PetError(e.toString()));
    }
  }

  Future<void> create(PetDto dto, String token) async {
    emit(PetLoading());
    try {
      await repository.create(dto, token);
      if (!isClosed) emit(PetInitial());
    } catch (e) {
      if (!isClosed) emit(PetError(e.toString()));
    }
  }

  Future<void> update(int id, PetDto dto, String token) async {
    emit(PetLoading());
    try {
      await repository.update(id, dto, token);
      if (!isClosed) emit(PetInitial());
    } catch (e) {
      if (!isClosed) emit(PetError(e.toString()));
    }
  }

  Future<void> delete(int id, String token) async {
    emit(PetLoading());
    try {
      await repository.delete(id, token);
      if (!isClosed) emit(PetInitial());
    } catch (e) {
      if (!isClosed) emit(PetError(e.toString()));
    }
  }
} 