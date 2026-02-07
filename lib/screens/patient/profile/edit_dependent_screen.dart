// ============================================
// 2️⃣ NEW: edit_dependent_screen.dart
// ============================================

import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aroggyapath/providers/dependent_provider.dart';
import 'package:aroggyapath/models/dependent_model.dart';

class EditDependentScreen extends StatefulWidget {
  const EditDependentScreen({super.key});

  @override
  State<EditDependentScreen> createState() => _EditDependentScreenState();
}

class _EditDependentScreenState extends State<EditDependentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _medicalNotesController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedRelationship;
  String _selectedGender = 'Male';
  bool _isActive = true;
  bool _isSaving = false;

  DependentModel? _dependent;

  final List<String> _relationships = [
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Spouse',
    'Child',
    'Other',
  ];

  final Color _cardBackgroundColor = const Color.fromRGBO(229, 238, 255, 1);
  final Gradient _primaryButtonGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0B3267), Color(0xFF1664CD)],
    stops: [0.3016, 1.0],
  );

  final Gradient _dangerButtonGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dependent == null) {
      _dependent = ModalRoute.of(context)!.settings.arguments as DependentModel;
      _populateFields();
    }
  }

  void _populateFields() {
    if (_dependent == null) return;

    _nameController.text = _dependent!.fullName;
    _selectedRelationship = _dependent!.relationship;
    _selectedGender = _dependent!.gender ?? 'Male';
    _selectedDate = _dependent!.dob;
    _contactController.text = _dependent!.phone ?? '';
    _medicalNotesController.text = _dependent!.notes ?? '';
    _isActive = _dependent!.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF0B3267),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDependent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectRelationship),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectDob)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await context.read<DependentProvider>().updateDependent(
      dependentId: _dependent!.id,
      fullName: _nameController.text.trim(),
      relationship: _selectedRelationship!,
      dob: _selectedDate!,
      gender: _selectedGender,
      phone: _contactController.text.trim(),
      notes: _medicalNotesController.text.trim(),
      isActive: _isActive,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.dependentUpdatedSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<DependentProvider>().error ??
                  AppLocalizations.of(context)!.failedToUpdateDependent,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dependent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.editDependent,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormCard(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(AppLocalizations.of(context)!.basicInformation),
          const SizedBox(height: 15),

          _buildDropdownField(),
          const SizedBox(height: 15),

          _buildTextField(
            controller: _nameController,
            label: AppLocalizations.of(context)!.fullName,
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty
                ? AppLocalizations.of(context)!.nameIsRequired
                : null,
          ),
          const SizedBox(height: 15),

          _buildDatePickerField(),
          const SizedBox(height: 20),

          _buildSectionTitle(AppLocalizations.of(context)!.genderLabel),
          const SizedBox(height: 10),
          _buildGenderSelector(),
          const SizedBox(height: 20),

          _buildSectionTitle('Status'),
          const SizedBox(height: 10),
          _buildStatusSelector(),
          const SizedBox(height: 20),

          _buildSectionTitle(AppLocalizations.of(context)!.contactDetails),
          const SizedBox(height: 15),

          _buildTextField(
            controller: _contactController,
            label: AppLocalizations.of(context)!.dependentContactHint,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 20),
          _buildSectionTitle(
            AppLocalizations.of(context)!.additionalInformation,
          ),
          const SizedBox(height: 15),

          _buildTextField(
            controller: _medicalNotesController,
            label: AppLocalizations.of(context)!.medicalNotesHint,
            maxLines: 3,
            icon: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0B3267),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF0B3267), size: 20)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B3267)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRelationship,
          hint: Text(
            AppLocalizations.of(context)!.relationshipLabel,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0B3267)),
          items: _relationships.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(_getLocalizedRelationship(value)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedRelationship = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF0B3267),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? AppLocalizations.of(context)!.dateOfBirth
                  : DateFormat('dd MMM, yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null
                    ? Colors.grey.shade400
                    : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: ['Male', 'Female'].map((gender) {
        final isSelected = _selectedGender == gender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = gender),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0B3267)
                      : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                _getLocalizedGender(gender),
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0B3267)
                      : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isActive = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isActive ? Colors.green : Colors.grey.shade300,
                  width: _isActive ? 1.5 : 1,
                ),
                boxShadow: _isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.of(context)!.active,
                style: TextStyle(
                  color: _isActive ? Colors.green : Colors.grey.shade600,
                  fontWeight: _isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isActive = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !_isActive ? Colors.orange : Colors.grey.shade300,
                  width: !_isActive ? 1.5 : 1,
                ),
                boxShadow: !_isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.of(context)!.inactive,
                style: TextStyle(
                  color: !_isActive ? Colors.orange : Colors.grey.shade600,
                  fontWeight: !_isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: _primaryButtonGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1664CD).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveDependent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    AppLocalizations.of(context)!.updateDependent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: _dangerButtonGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF512F).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedGender(String gender) {
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      if (gender.toLowerCase() == 'male') return l10n.male;
      if (gender.toLowerCase() == 'female') return l10n.female;
    }
    return gender;
  }

  String _getLocalizedRelationship(String rel) {
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      switch (rel.toLowerCase()) {
        case 'son':
          return l10n.relSon;
        case 'daughter':
          return l10n.relDaughter;
        case 'father':
          return l10n.relFather;
        case 'mother':
          return l10n.relMother;
        case 'brother':
          return l10n.relBrother;
        case 'sister':
          return l10n.relSister;
        case 'spouse':
          return l10n.relSpouse;
        case 'child':
          return l10n.relChild;
        default:
          return l10n.relOther;
      }
    }
    return rel;
  }
}
