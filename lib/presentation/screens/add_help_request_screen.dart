import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../blocs/help_request_cubit.dart';
import '../../data/models/help_request_dto.dart';
import '../partials/base_app_bar.dart';
import '../../core/enums/emergency_level.dart';
import '../../core/enums/help_request_status.dart';
import '../../core/constants/admob_banner_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petsolive/data/providers/image_upload_provider.dart';
import 'dart:io';
import '../../core/network/auth_service.dart';

class AddHelpRequestScreen extends StatefulWidget {
  const AddHelpRequestScreen({Key? key}) : super(key: key);

  @override
  State<AddHelpRequestScreen> createState() => _AddHelpRequestScreenState();
}

class _AddHelpRequestScreenState extends State<AddHelpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  EmergencyLevel _emergencyLevel = EmergencyLevel.low;
  bool _isLoading = false;
  // --- EKLENENLER ---
  File? _selectedImageFile;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _currentUser;
  String? _token;
  // --- SON EKLENENLER ---

  void _setLoadingByState(BuildContext context) {
    final state = context.read<HelpRequestCubit>().state;
    setState(() {
      _isLoading = state is HelpRequestLoading;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final authService = AuthService();
    final token = await authService.getToken();
    final user = await authService.getUser();
    if (!mounted) return;
    setState(() {
      _token = token;
      _currentUser = user;
      if (user != null) {
        _contactNameController.text = user['username'] ?? '';
        _contactPhoneController.text = user['phoneNumber'] ?? '';
        _contactEmailController.text = user['email'] ?? '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    if (_token == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('help_requests.login_required'.tr())),
      );
      setState(() => _isLoading = false);
      return;
    }
    final user = _currentUser!;
    final username = user['username'] ?? '';
    final phone = user['phoneNumber'] ?? '';
    final email = user['email'] ?? '';
    final userId = user['id'] is int
        ? user['id'] as int
        : int.tryParse(user['id']?.toString() ?? '0') ?? 0;
    final dto = HelpRequestDto(
      id: 0,
      title: _titleController.text,
      description: _descriptionController.text,
      emergencyLevel: _emergencyLevel,
      location: _locationController.text,
      imageUrl: _imageUrlController.text,
      userId: userId,
      userName: username,
    contactName: _contactNameController.text.isNotEmpty ? _contactNameController.text : username,
    contactPhone: _contactPhoneController.text.isNotEmpty ? _contactPhoneController.text : phone,
    contactEmail: _contactEmailController.text.isNotEmpty ? _contactEmailController.text : email,
      createdAt: DateTime.now(),
      status: HelpRequestStatus.Active,
    );
    try {
      final cubit = context.read<HelpRequestCubit>();
      await cubit.create(dto, _token!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('help_requests.add_failed'.tr(args: [e.toString()])), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingImage = true;
      });
      try {
        final url = await ImageUploadProvider.uploadToImgbb(_selectedImageFile!);
        setState(() {
          _imageUrlController.text = url;
          _isUploadingImage = false;
        });
      } catch (e) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yüklenemedi: $e')),
        );
      }
    }
  }

  String _emergencyLevelLabel(EmergencyLevel level) {
    switch (level) {
      case EmergencyLevel.low:
        return 'help_requests.tab_low'.tr();
      case EmergencyLevel.medium:
        return 'help_requests.tab_medium'.tr();
      case EmergencyLevel.high:
        return 'help_requests.tab_high'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: BaseAppBar(
        title: 'help_requests.add_title'.tr(),
        showLogo: false,
      ),
      body: BlocListener<HelpRequestCubit, HelpRequestState>(
        listener: (context, state) async {
          _setLoadingByState(context);
          if (state is HelpRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('help_requests.add_failed'.tr(args: [state.error])), backgroundColor: Colors.red),
            );
          } else if (state is HelpRequestInitial) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('help_requests.add_success'.tr()), backgroundColor: Colors.green),
            );
            await Future.delayed(const Duration(milliseconds: 800));
            if (context.mounted) Navigator.of(context).pop(true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (_imageUrlController.text.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 18),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 300,
                                        height: 300,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        Future.microtask(() => Navigator.of(ctx).pop());
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(Icons.close, color: Colors.white, size: 28),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrlController.text,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.zoom_in, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // --- Temel Bilgiler ---
                Row(
                  children: [
                    Icon(Icons.assignment, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text('help_requests.section_basic'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'help_requests.title'.tr(), prefixIcon: Icon(Icons.title)),
                  validator: (v) => v == null || v.isEmpty ? 'help_requests.title_required'.tr() : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'help_requests.description'.tr(), prefixIcon: Icon(Icons.description)),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'help_requests.description_required'.tr() : null,
                ),
                const SizedBox(height: 18),
                // --- Aciliyet ve Konum ---
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 22),
                    const SizedBox(width: 8),
                    Text('help_requests.section_emergency'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EmergencyLevel>(
                  value: _emergencyLevel,
                  decoration: InputDecoration(labelText: 'help_requests.emergency_level'.tr(), prefixIcon: Icon(Icons.priority_high)),
                  items: EmergencyLevel.values.map((e) => DropdownMenuItem<EmergencyLevel>(
                    value: e,
                    child: Text(_emergencyLevelLabel(e)),
                  )).toList(),
                  onChanged: (EmergencyLevel? v) => setState(() => _emergencyLevel = v ?? EmergencyLevel.low),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: 'help_requests.location'.tr(), prefixIcon: Icon(Icons.location_on)),
                  validator: (v) => v == null || v.isEmpty ? 'help_requests.location_required'.tr() : null,
                ),
                const SizedBox(height: 18),
                // --- İletişim Bilgileri ---
                Row(
                  children: [
                    Icon(Icons.person, color: colorScheme.secondary, size: 22),
                    const SizedBox(width: 8),
                    Text('help_requests.section_contact'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactNameController,
                  decoration: InputDecoration(labelText: 'help_requests.contact_name'.tr(), prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactPhoneController,
                  decoration: InputDecoration(labelText: 'help_requests.contact_phone'.tr(), prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v == null || v.isEmpty ? 'help_requests.contact_phone_required'.tr() : null,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactEmailController,
                  decoration: InputDecoration(labelText: 'help_requests.contact_email'.tr(), prefixIcon: Icon(Icons.email)),
                  validator: (v) => v == null || v.isEmpty ? 'help_requests.contact_email_required'.tr() : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                // --- Görsel ---
                Row(
                  children: [
                    Icon(Icons.image, color: Colors.teal, size: 22),
                    const SizedBox(width: 8),
                    Text('help_requests.section_image'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _selectedImageFile != null
                              ? Image.file(_selectedImageFile!, width: 120, height: 120, fit: BoxFit.cover)
                              : (_imageUrlController.text.isNotEmpty
                                  ? Image.network(_imageUrlController.text, width: 120, height: 120, fit: BoxFit.cover)
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                                    )),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: _isUploadingImage
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(labelText: 'help_requests.image_url'.tr(), prefixIcon: Icon(Icons.link)),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: _isLoading
                      ? Text('help_requests.saving'.tr())
                      : Text('help_requests.save'.tr()),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                AdmobBannerWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
