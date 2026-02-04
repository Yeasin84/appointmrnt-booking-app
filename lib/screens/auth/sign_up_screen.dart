import 'package:flutter/material.dart';
import 'package:aroggyapath/widgets/custom_button.dart';
import 'package:aroggyapath/widgets/custom_text_field.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  final String userType;
  const SignUpScreen({super.key, required this.userType});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Doctor Specific Controllers
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  String? _selectedSpecialty;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Specialty options with hardcoded fallback
  List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Gynecologist',
    'Orthopedic',
    'Dentist',
    'ENT',
    'Psychiatrist',
  ];
  bool _isLoadingCategories = true;

  // Referral System Setting
  bool _isReferralSystemEnabled = false;
  bool _isLoadingReferralSetting = true;

  @override
  void initState() {
    super.initState();
    if (widget.userType.toLowerCase() == 'doctor') {
      _fetchCategories();
      _fetchReferralSetting();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.getAllCategories();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoryData = response['data'];
        if (categoryData.isNotEmpty) {
          setState(() {
            _specialties = categoryData
                .map((c) => (c['name'] ?? c['speciality_name'] ?? '') as String)
                .where((s) => s.isNotEmpty)
                .toList();
            _isLoadingCategories = false;
          });
        } else {
          // Keep fallback data if DB is empty
          setState(() => _isLoadingCategories = false);
        }
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      setState(() => _isLoadingCategories = false); // Keep fallback data
    }
  }

  Future<void> _fetchReferralSetting() async {
    try {
      final response = await ApiService.getReferralSetting();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _isReferralSystemEnabled =
              response['data']['referralSystemEnabled'] ?? false;
          _isLoadingReferralSetting = false;
        });
        debugPrint('✅ Referral system enabled: $_isReferralSystemEnabled');
      } else {
        setState(() => _isLoadingReferralSetting = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching referral setting: $e');
      setState(() => _isLoadingReferralSetting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licenseController.dispose();
    _referralController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  /// Validate form
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check password match
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar(l10n.passwordsDoNotMatch, isError: true);
      return false;
    }

    // Check password length
    if (_passwordController.text.length < 6) {
      _showSnackBar(l10n.passwordAtLeast6, isError: true);
      return false;
    }

    // Doctor-specific validation
    if (widget.userType.toLowerCase() == 'doctor') {
      if (_licenseController.text.trim().isEmpty) {
        _showSnackBar(l10n.licenseRequired, isError: true);
        return false;
      }

      if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
        _showSnackBar(l10n.specialtyRequired, isError: true);
        return false;
      }

      if (_experienceController.text.trim().isEmpty) {
        _showSnackBar(l10n.experienceRequired, isError: true);
        return false;
      }

      // Referral code mandatory check if system is enabled
      if (_isReferralSystemEnabled && _referralController.text.trim().isEmpty) {
        _showSnackBar(l10n.enterReferralCode, isError: true);
        return false;
      }
    }

    return true;
  }

  ///  Handle Sign Up
  void _handleSignUp() async {
    // Validate form
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Starting registration...');
      debugPrint('   User Type: ${widget.userType}');
      debugPrint('   Name: ${_nameController.text.trim()}');
      debugPrint('   Email: ${_emailController.text.trim()}');

      //  Call ApiService.register with correct parameters
      final result = await ApiService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: widget.userType.toLowerCase(), // 'doctor' or 'patient'
        medicalLicenseNumber: widget.userType.toLowerCase() == 'doctor'
            ? _licenseController.text.trim()
            : null,
        specialty: widget.userType.toLowerCase() == 'doctor'
            ? _selectedSpecialty
            : null,
        experienceYears: widget.userType.toLowerCase() == 'doctor'
            ? _experienceController.text.trim()
            : null,
        referralCode: widget.userType.toLowerCase() == 'doctor'
            ? _referralController.text.trim()
            : null,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      debugPrint('📥 Registration result: ${result['success']}');

      if (result['success'] == true) {
        debugPrint('Registration successful');

        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(
          result['message'] ?? l10n.registrationSuccessful,
          isError: false,
        );

        // Small delay for better UX
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Go back to login screen
        Navigator.pop(context);
      } else {
        debugPrint('Registration failed: ${result['message']}');

        String errorMessage = result['message'] ?? 'Registration failed';

        // Handle validation errors
        if (result['errors'] != null && result['errors'] is List) {
          final errors = result['errors'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors.join(', ');
          }
        }

        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Registration error: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(l10n.connectionError, isError: true);
    }
  }

  ///  Show snackbar
  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDoctor = widget.userType.toLowerCase() == 'doctor';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo_app.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.medical_services,
                      size: 80,
                      color: Color(0xFF1664CD),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.createAccount(widget.userType),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B3267),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.fillDetails,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Full Name
                Text(
                  l10n.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: l10n.enterFullName,
                  controller: _nameController,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1664CD),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterFullName;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Email
                Text(
                  l10n.emailAddressStar,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: l10n.emailExample,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF1664CD),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterEmail;
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),

                // Doctor-specific fields
                if (isDoctor) ...[
                  const SizedBox(height: 15),

                  // Medical License
                  Text(
                    l10n.medicalLicenseNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: l10n.enterLicenseNumber,
                    controller: _licenseController,
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF1664CD),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Referral Code (Dynamic Visibility)
                  if (_isLoadingReferralSetting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_isReferralSystemEnabled) ...[
                    Text(
                      l10n.referralCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B3267),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      hintText: l10n.enterReferralCode,
                      controller: _referralController,
                      prefixIcon: const Icon(
                        Icons.discount_outlined,
                        color: Color(0xFF1664CD),
                      ),
                      validator: (value) {
                        if (_isReferralSystemEnabled &&
                            (value == null || value.trim().isEmpty)) {
                          return l10n.enterReferralCode;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Specialty
                  Text(
                    l10n.medicalSpecialty,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: _isLoadingCategories
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedSpecialty,
                              hint: Text(l10n.selectSpecialty),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF1664CD),
                              ),
                              items: _specialties
                                  .map(
                                    (specialty) => DropdownMenuItem(
                                      value: specialty,
                                      child: Text(specialty),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSpecialty = value;
                                });
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Experience
                  Text(
                    l10n.yearsExperienceStar,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3267),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: l10n.yearsExperienceExample,
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      Icons.work_outline,
                      color: Color(0xFF1664CD),
                    ),
                  ),
                ],

                const SizedBox(height: 15),

                // Password
                Text(
                  l10n.passwordStar,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: l10n.passwordLength,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1664CD),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordStar;
                    }
                    if (value.length < 6) {
                      return l10n.passwordAtLeast6;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Confirm Password
                Text(
                  l10n.confirmPasswordStar,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B3267),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hintText: l10n.reenterPassword,
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1664CD),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.confirmPasswordStar;
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Sign Up Button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1664CD),
                        ),
                      )
                    : CustomButton(
                        text: l10n.createAccountBtn,
                        onPressed: _handleSignUp,
                      ),

                const SizedBox(height: 20),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        l10n.signInLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1664CD),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
