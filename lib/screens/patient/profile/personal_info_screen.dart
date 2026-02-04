import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import '../../../services/location_service.dart';
import '../../../providers/user_provider.dart';
import 'package:geolocator/geolocator.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUpdating = false;
  double? _currentLat;
  double? _currentLng;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _currentLat = user.latitude;
      _currentLng = user.longitude;
    }
  }

  Future<void> _getCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLocating = true);

    try {
      final locationService = LocationService();

      bool serviceEnabled = await locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationDialog(
            l10n.locationServicesDisabledTitle,
            l10n.locationServicesDisabledMessage,
            () => Geolocator.openLocationSettings(),
          );
        }
        return;
      }

      LocationPermission permission = await locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await locationService.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationDialog(
            l10n.locationPermissionRequiredTitle,
            l10n.locationPermissionRequiredMessage,
            () => Geolocator.openAppSettings(),
          );
        }
        return;
      }

      final position = await locationService.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      final address = await locationService.getAddressFromLatLng(latLng);

      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _addressController.text = address;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Location updated')));
      }
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorMsg(e))));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationDialog(
    String title,
    String message,
    VoidCallback onOpenSettings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
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
        });
        debugPrint('📸 Image selected: ${image.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorMsg(e))),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nameEmptyError)),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final userProvider = context.read<UserProvider>();

      // ✅ FIXED: Use updateUserProfile instead of updateProfile
      final success = await userProvider.updateUserProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? ""
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? ""
            : _addressController.text.trim(),
        latitude: _currentLat,
        longitude: _currentLng,
        profileImage:
            _selectedImage, // ✅ Pass File directly, provider will convert
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${AppLocalizations.of(context)!.profileUpdatedSuccess}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedImage = null;
        });

        // ✅ Refresh the data
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userProvider.error ?? AppLocalizations.of(context)!.updateFailed,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorMsg(e))),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.personalInfo,
          style: const TextStyle(
            color: Color(0xFF0B3267),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (user?.profileImage != null &&
                              user!.profileImage!.isNotEmpty)
                        ? NetworkImage(user.profileImage!)
                        : const AssetImage('assets/images/profile.png')
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B3267), Color(0xFF1664CD)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.tapToChangePicture,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _buildInfoField(
              icon: Icons.person_outline,
              controller: _nameController,
              label: AppLocalizations.of(context)!.fullName,
            ),
            const SizedBox(height: 20),

            _buildInfoField(
              icon: Icons.email_outlined,
              controller: _emailController,
              label: AppLocalizations.of(context)!.emailAddress,
              enabled: false,
            ),
            const SizedBox(height: 20),

            _buildInfoField(
              icon: Icons.phone_outlined,
              controller: _phoneController,
              label: AppLocalizations.of(context)!.phoneNumber,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            _buildInfoField(
              icon: Icons.location_on_outlined,
              controller: _addressController,
              label: AppLocalizations.of(context)!.address,
              suffixIcon: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.my_location,
                        color: Color(0xFF1664CD),
                      ),
                      onPressed: _getCurrentLocation,
                    ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D53C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.updateProfile,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
        color: enabled ? Colors.white : Colors.grey[100],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1664CD)),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
              ),
            ),
          ),
          if (enabled && suffixIcon == null)
            const Icon(Icons.edit, size: 20, color: Colors.grey),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
