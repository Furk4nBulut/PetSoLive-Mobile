import '../../domain/repositories/help_request_repository.dart';
import '../models/help_request_dto.dart';
import '../providers/help_request_api_service.dart';
import '../local/help_request_local_data_source.dart';

class HelpRequestRepositoryImpl implements HelpRequestRepository {
  final HelpRequestApiService apiService;
  final HelpRequestLocalDataSource localDataSource;

  HelpRequestRepositoryImpl(this.apiService, this.localDataSource);

  @override
  Future<List<HelpRequestDto>> getAll() async {
    try {
      final apiRequests = await apiService.getAll();
      await localDataSource.saveRequests(apiRequests);
      return apiRequests;
    } catch (_) {
      final cached = await localDataSource.getRequests();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<HelpRequestDto?> getById(int id) => apiService.getById(id);

  @override
  Future<void> create(HelpRequestDto dto, String token) => apiService.create(dto, token);

  @override
  Future<void> update(int id, HelpRequestDto dto, String token) => apiService.update(id, dto, token);

  @override
  Future<void> delete(int id, String token) => apiService.delete(id, token);

  @override
  Future<List<HelpRequestDto>> fetchFromApiAndSaveToLocal() async {
    final apiList = await apiService.getAll();
    await localDataSource.saveRequests(apiList);
    return await localDataSource.getRequests();
  }
} 