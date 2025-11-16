import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/pet_dto.dart';
import '../../data/local/session_manager.dart';
import '../partials/base_app_bar.dart';
import '../../core/constants/admob_banner_widget.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../data/providers/pet_api_service.dart';
import '../../data/providers/image_upload_provider.dart';

class AddPetScreen extends StatefulWidget {
  final PetDto? pet;
  final bool isEdit;

  const AddPetScreen({Key? key, this.pet, this.isEdit = false}) : super(key: key);

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  DateTime? _selectedDate;
  final _descriptionController = TextEditingController();
  final _vaccinationStatusController = TextEditingController();
  final _microchipIdController = TextEditingController();
  File? _selectedImage;
  String? _uploadedImageUrl;
  final picker = ImagePicker();
  bool? _isNeutered = false;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Erkek', 'Dişi'];

  Future<List<String>> fetchSpeciesList() async {
    // Burada gerçek API çağrısı yapılabilir
    await Future.delayed(const Duration(milliseconds: 300));
    // Örnek veri, API'dan geliyormuş gibi
    return ['Köpek', 'Kedi', 'Kuş', 'Hamster', 'Balık', 'Diğer...'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Resmi upload et ve url'yi kaydet
      try {
        final url = await ImageUploadProvider.uploadToImgbb(_selectedImage!);
        setState(() {
          _uploadedImageUrl = url;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir resim yükleyin!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sessionManager = SessionManager();
      final token = await sessionManager.getToken() ?? '';

      await PetApiService().createPetMultipart(
        name: _nameController.text,
        species: _speciesController.text,
        breed: _breedController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender ?? '',
        weight: double.tryParse(_weightController.text) ?? 0,
        color: _colorController.text,
        dateOfBirth: _selectedDate ?? DateTime.now(),
        description: _descriptionController.text,
        microchipId: _microchipIdController.text,
        vaccinationStatus: _vaccinationStatusController.text,
        isNeutered: _isNeutered,
        imageFile: _selectedImage!,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pets.add_success'.tr())),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('form.error'.tr(args: [e.toString()]))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'pets.add'.tr(),
        showLogo: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              Row(
                children: [
                  Icon(Icons.add, size: 36, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text('pets.add'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('pets.add_subtitle'.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 18),
              if (_selectedImage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.file(_selectedImage!, width: 120, height: 120),
                  ),
                ),
              // Kimlik Bilgileri
              Row(
                children: [
                  Icon(Icons.badge, color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  Text('edit_pet.identity'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'pets.name'.tr()),
                      validator: (v) => v == null || v.isEmpty ? 'form.required'.tr() : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _speciesController,
                      decoration: InputDecoration(labelText: 'pets.species'.tr()),
                      validator: (v) => v == null || v.isEmpty ? 'form.required'.tr() : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _breedController,
                      decoration: InputDecoration(labelText: 'pets.breed'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text('pets.gender_' + g).tr())).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      decoration: InputDecoration(labelText: 'pets.gender'.tr()),
                      validator: (v) => (v == null || v.isEmpty) ? 'form.required'.tr() : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Fiziksel Özellikler
              Row(
                children: [
                  Icon(Icons.pets, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text('edit_pet.physical'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: 'pets.age'.tr()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(labelText: 'pets.color'.tr()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(labelText: 'pets.weight'.tr()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime(2020, 1, 1),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: 'pets.date_of_birth'.tr()),
                        child: Text(
                          _selectedDate != null
                              ? _selectedDate!.toIso8601String().split('T').first
                              : 'form.select'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Sağlık Bilgileri
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('edit_pet.health'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vaccinationStatusController,
                      decoration: InputDecoration(labelText: 'pets.vaccination_status'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      title: Text('pets.is_neutered'.tr()),
                      value: _isNeutered ?? false,
                      onChanged: (v) => setState(() => _isNeutered = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Açıklama
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('pets.description'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'pets.description'.tr()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _microchipIdController,
                decoration: InputDecoration(labelText: 'pets.microchip_id'.tr()),
              ),
              const SizedBox(height: 12),
              // Resim seçme ve önizleme:
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Resim Seç'),
              ),
              if (_selectedImage != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Center(
                            child: Image.file(_selectedImage!, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.file(_selectedImage!, width: 120, height: 120),
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      label: _isLoading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('form.save'.tr()),
                    ),
                  ),
                ],
              ),
              AdmobBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
