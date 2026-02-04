import 'dart:io';
import 'package:aroggyapath/screens/location/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:aroggyapath/services/api_service.dart';
import '../../../providers/user_provider.dart';

class DoctorPersonalInfoScreen extends StatefulWidget {
  const DoctorPersonalInfoScreen({super.key});

  @override
  State<DoctorPersonalInfoScreen> createState() =>
      _DoctorPersonalInfoScreenState();
}

class _DoctorPersonalInfoScreenState extends State<DoctorPersonalInfoScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Location variables
  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  final ImagePicker _picker = ImagePicker();

  // Specialty options (Fetched from backend)
  List<String> _specialtyOptions = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCategories();

    // Track changes
    _bioController.addListener(() => setState(() => _hasChanges = true));
    _nameController.addListener(() => setState(() => _hasChanges = true));
    _specialtyController.addListener(() => setState(() => _hasChanges = true));
    _degreeController.addListener(() => setState(() => _hasChanges = true));
    _addressController.addListener(() => setState(() => _hasChanges = true));
    _phoneController.addListener(() => setState(() => _hasChanges = true));
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.getAllCategories();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoryData = response['data'];
        setState(() {
          _specialtyOptions = categoryData
              .map((c) => c['speciality_name'] as String)
              .toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  void _loadUserData() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _bioController.text = user.bio ?? '';
      _specialtyController.text = user.specialty ?? '';
      _degreeController.text = user.medicalLicenseNumber ?? '';
      _currentImageUrl = user.profileImage;

      // ✅ Load location - check if your User model has latitude/longitude properties
      // Option 1: If user has latitude and longitude properties directly
      _latitude = user.latitude;
      _longitude = user.longitude;

      // Option 2: If user has a location object with lat/lng properties
      // _latitude = user.location?.lat;
      // _longitude = user.location?.lng;

      // Option 3: If location is a Map<String, dynamic>
      // if (user.location != null && user.location is Map) {
      //   final locationMap = user.location as Map<String, dynamic>;
      //   _latitude = locationMap['lat'] != null
      //       ? double.tryParse(locationMap['lat'].toString())
      //       : null;
      //   _longitude = locationMap['lng'] != null
      //       ? double.tryParse(locationMap['lng'].toString())
      //       : null;
      // }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasChanges = true;
        });
        debugPrint('📸 Image selected: ${image.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorMsg(e))),
        );
      }
    }
  }

  void _showSpecialtyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.selectSpecialty,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _specialtyOptions.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context)!.noResultsFound),
                    )
                  : ListView.builder(
                      itemCount: _specialtyOptions.length,
                      itemBuilder: (context, index) {
                        final specialty = _specialtyOptions[index];
                        final isSelected =
                            _specialtyController.text == specialty;

                        return ListTile(
                          title: Text(_getLocalizedSpecialty(specialty)),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFF1664CD),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _specialtyController.text = specialty;
                              _hasChanges = true;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationAddress = result['address'];
        _addressController.text = _locationAddress ?? '';
        _hasChanges = true;
      });

      debugPrint('📍 Location selected:');
      debugPrint('   - Latitude: $_latitude');
      debugPrint('   - Longitude: $_longitude');
      debugPrint('   - Address: $_locationAddress');
    }
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noChangesToSave)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();

      debugPrint('💾 Saving profile with location:');
      debugPrint('   - Latitude: $_latitude');
      debugPrint('   - Longitude: $_longitude');
      debugPrint('   - Address: ${_addressController.text}');

      // ✅ Create location map if both lat and lng are available
      Map<String, dynamic>? locationData;
      if (_latitude != null && _longitude != null) {
        locationData = {
          'lat': _latitude.toString(),
          'lng': _longitude.toString(),
        };
      }

      final success = await userProvider.updateUserProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        specialty: _specialtyController.text.trim(),
        profileImage: _selectedImage,
        latitude: _latitude, // ✅ Pass as separate parameters
        longitude: _longitude, // ✅ Pass as separate parameters
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.profileUpdatedSuccess,
              ),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _hasChanges = false;
            _selectedImage = null;
            _currentImageUrl = userProvider.user?.profileImage;
          });
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '{userProvider.error ?? AppLocalizations.of(context)!.updateFailed}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorMsg(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2C49)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.personalInfo,
              style: const TextStyle(
                color: Color(0xFF1B2C49),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.editYourProfile,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F0FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.profilePicture,
                          style: const TextStyle(
                            color: Color(0xFF1B2C49),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (_currentImageUrl != null &&
                                            _currentImageUrl!.isNotEmpty
                                        ? NetworkImage(_currentImageUrl!)
                                        : const AssetImage(
                                                'assets/images/doctor_booking.png',
                                              )
                                              as ImageProvider),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                  color: Color(0xFF1B2C49),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.tapToChangePicture,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Bio Section
                Text(
                  AppLocalizations.of(context)!.addBio,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0FF),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFB3CEFF)),
                  ),
                  child: TextField(
                    controller: _bioController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1B2C49),
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.bioHint,
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info Fields
                _buildInfoCard(
                  icon: Icons.person_outline,
                  controller: _nameController,
                  hint: AppLocalizations.of(context)!.enterFullName,
                ),
                _buildSpecialtyCard(),
                _buildInfoCard(
                  icon: Icons.school_outlined,
                  controller: _degreeController,
                  enabled: false,
                  hint: AppLocalizations.of(context)!.degreeHint,
                ),
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  enabled: false,
                  hint: AppLocalizations.of(context)!.emailLockedNote,
                ),

                // Location Card with Map Icon
                _buildLocationCard(),

                _buildInfoCard(
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  hint: AppLocalizations.of(context)!.contactNumberHint,
                ),

                const SizedBox(height: 30),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1664CD),
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.updateProfile,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF1664CD),
            size: 22,
          ),
        ),
        title: TextField(
          controller: _addressController,
          readOnly: true,
          onTap: _openLocationPicker,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1B2C49),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: AppLocalizations.of(context)!.clinicLocationHint,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.my_location,
            color: Color(0xFF1664CD),
            size: 24,
          ),
          onPressed: _openLocationPicker,
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_search_outlined,
            color: Color(0xFF1B2C49),
            size: 22,
          ),
        ),
        title: TextField(
          controller: _specialtyController,
          readOnly: true,
          onTap: _showSpecialtyPicker,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1B2C49),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: AppLocalizations.of(context)!.selectSpecialty,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xFF1B2C49),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1B2C49), size: 22),
        ),
        title: TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? const Color(0xFF1B2C49) : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        trailing: Icon(
          enabled ? Icons.edit_outlined : Icons.lock_outline,
          color: enabled ? const Color(0xFF1B2C49) : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _specialtyController.dispose();
    _degreeController.dispose();
    super.dispose();
  }

  String _getLocalizedSpecialty(String spec) {
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      switch (spec) {
        case 'Cardiologist':
          return l10n.specCardiologist;
        case 'Dermatologist':
          return l10n.specDermatologist;
        case 'Neurologist':
          return l10n.specNeurologist;
        case 'Orthopedic':
          return l10n.specOrthopedic;
        case 'Pediatrician':
          return l10n.specPediatrician;
        case 'Psychiatrist':
          return l10n.specPsychiatrist;
        case 'General Physician':
          return l10n.specGeneralPhysician;
        case 'ENT Specialist':
          return l10n.specENT;
        case 'Gynecologist':
          return l10n.specGynecologist;
        case 'Ophthalmologist':
          return l10n.specOphthalmologist;
        case 'Dentist':
          return l10n.specDentist;
        case 'Urologist':
          return l10n.specUrologist;
        default:
          return spec;
      }
    }
    return spec;
  }
}
