import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aroggyapath/models/doctor_model.dart';
import 'package:aroggyapath/models/dependent_model.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'package:aroggyapath/providers/dependent_provider.dart';
import 'package:aroggyapath/utils/api_config.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class BookAppointmentScreen extends StatefulWidget {
  final dynamic doctor;
  final bool isReschedule;
  final AppointmentModel? existingAppointment;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
    this.isReschedule = false,
    this.existingAppointment,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String selectedType = "Physical Visit";
  DateTime? selectedDate;
  TimeSlot? selectedTimeSlot;
  DependentModel? selectedDependent;
  final TextEditingController _symptomsController = TextEditingController();

  final List<XFile> _medicalDocuments = [];
  XFile? _paymentScreenshot;

  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<TimeSlot> availableSlots = [];

  final ImagePicker _picker = ImagePicker();

  Doctor? get doctorObject {
    if (widget.doctor is Doctor) return widget.doctor as Doctor;
    if (widget.doctor is Map<String, dynamic>) {
      return Doctor.fromJson(widget.doctor as Map<String, dynamic>);
    }
    return null;
  }

  String get doctorId {
    if (widget.doctor is Map<String, dynamic>) {
      final map = widget.doctor as Map<String, dynamic>;
      return (map['_id'] ?? map['id'] ?? '').toString();
    }
    if (widget.doctor is Doctor) {
      return (widget.doctor as Doctor).id;
    }
    return '';
  }

  String get doctorName {
    if (widget.doctor is Map<String, dynamic>) {
      final map = widget.doctor as Map<String, dynamic>;
      return (map['fullName'] ?? map['name'] ?? 'Dr. Unknown').toString();
    }
    if (widget.doctor is Doctor) {
      return (widget.doctor as Doctor).name;
    }
    return 'Dr. Unknown';
  }

  @override
  void initState() {
    super.initState();

    // ✅ Pre-fill data if reschedule mode
    if (widget.isReschedule && widget.existingAppointment != null) {
      _prefillDataForReschedule();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DependentProvider>().fetchDependents();
    });
  }

  // ✅ NEW: Pre-fill existing appointment data
  void _prefillDataForReschedule() {
    final appt = widget.existingAppointment!;

    // Set appointment type
    if (appt.appointmentType?.toLowerCase() == 'video') {
      selectedType = "Video Call";
    } else {
      selectedType = "Physical Visit";
    }

    // Set symptoms
    if (appt.symptoms != null && appt.symptoms!.isNotEmpty) {
      _symptomsController.text = appt.symptoms!;
    }

    // Set date and fetch slots
    selectedDate = appt.appointmentDate;
    if (selectedDate != null) {
      _fetchAvailableSlots(selectedDate!);
    }

    debugPrint('📝 Pre-filled data for reschedule:');
    debugPrint('   Type: $selectedType');
    debugPrint('   Date: $selectedDate');
    debugPrint('   Symptoms: ${_symptomsController.text}');
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0D53C1)),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null;
        availableSlots = [];
      });
      await _fetchAvailableSlots(picked);
    }
  }

  Future<void> _fetchAvailableSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);

    try {
      final response = await _fetchFromBackend(date);

      if (response != null && response['success'] == true) {
        final slotsData = response['data']['slots'] as List;
        final unbookedSlots = slotsData
            .map((slot) => TimeSlot.fromJson(slot))
            .where((slot) => slot.isBooked != true)
            .toList();

        setState(() {
          availableSlots = unbookedSlots;
        });
      } else {
        _loadFromWeeklySchedule(date);
      }
    } catch (e) {
      _loadFromWeeklySchedule(date);
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchFromBackend(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.appointments}/available',
            ),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'doctorId': doctorId,
              'date': DateFormat('yyyy-MM-dd').format(date),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Backend exception: $e');
    }
    return null;
  }

  void _loadFromWeeklySchedule(DateTime date) {
    final doctor = doctorObject;

    if (doctor == null ||
        doctor.weeklySchedule == null ||
        doctor.weeklySchedule!.isEmpty) {
      setState(() => availableSlots = []);
      return;
    }

    final dayName = _getDayName(date);
    WeeklySchedule? daySchedule;

    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.day.toLowerCase() == dayName.toLowerCase() &&
          schedule.isActive) {
        daySchedule = schedule;
        break;
      }
    }

    if (daySchedule == null) {
      setState(() => availableSlots = []);
      return;
    }

    setState(() {
      availableSlots = daySchedule!.slots;
    });
  }

  String _getDayName(DateTime date) {
    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return dayNames[date.weekday - 1];
  }

  Future<void> _pickMedicalDocuments() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty && mounted) {
      setState(() => _medicalDocuments.addAll(picked));
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _paymentScreenshot = picked);
    }
  }

  // ✅ UPDATED: Handle both create and reschedule
  Future<void> _submitAppointment() async {
    if (doctorId.isEmpty || doctorId.length < 10) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidDoctorBooking),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDate == null || selectedTimeSlot == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectDateTime)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.isReschedule) {
        await _handleReschedule();
      } else {
        await _handleNewAppointment();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ NEW: Handle reschedule
  Future<void> _handleReschedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Cancel old appointment
      final cancelResponse = await http.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.appointments}/${widget.existingAppointment!.id}/status',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': 'cancelled'}),
      );

      if (cancelResponse.statusCode < 200 || cancelResponse.statusCode >= 300) {
        throw Exception('Failed to cancel old appointment');
      }

      // Create new appointment
      await _handleNewAppointment();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rescheduleFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW: Helper to compress images
  Future<File> _compressImage(String path) async {
    try {
      final String targetPath = '${path}_compressed.jpg';
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 70, // Good balance of size/quality
        minWidth: 1280, // Reasonable max dimension
        minHeight: 1280,
      );

      if (result != null) {
        debugPrint(
          '✅ Compressed: ${(await File(path).length()) / 1024}KB -> ${(await File(result.path).length()) / 1024}KB',
        );
        return File(result.path);
      }
    } catch (e) {
      debugPrint('⚠️ Compression failed: $e');
    }
    return File(path); // Fallback to original
  }

  // ✅ NEW: Handle new appointment creation logic
  Future<void> _handleNewAppointment() async {
    try {
      // 1. Prepare Request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appointments}'),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 2. Prepare Data Payload
      String backendType = selectedType == "Physical Visit"
          ? "physical"
          : "video";

      Map<String, dynamic> bookedForPayload;
      if (selectedDependent == null) {
        bookedForPayload = {'type': 'self'};
      } else {
        bookedForPayload = {
          'type': 'dependent',
          'dependentId': selectedDependent!.id,
          'dependentName': selectedDependent!.fullName, // Added for clarity
          'relationship': selectedDependent!.relationship, // Added for clarity
        };
      }

      // 3. Add Fields
      // Note: We send symptoms as a plain field. If backend logic relies on this being
      // saved BEFORE file processing completes, compression helps by speeding up the request.
      final fields = {
        'doctorId': doctorId,
        'appointmentType': backendType,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'time': selectedTimeSlot!.start,
        'symptoms': _symptomsController.text.trim(),
        'bookedFor': json.encode(bookedForPayload),
      };

      request.fields.addAll(fields);
      debugPrint('📤 Sending Appointment Fields: $fields');

      // 4. Compress & Add Medical Documents
      if (_medicalDocuments.isNotEmpty) {
        debugPrint(
          '📸 Compressing ${_medicalDocuments.length} medical documents...',
        );
        for (var file in _medicalDocuments) {
          final compressedFile = await _compressImage(file.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'medicalDocuments',
              compressedFile.path,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        }
      }

      // 5. Compress & Add Payment Screenshot
      if (selectedType == "Video Call" && _paymentScreenshot != null) {
        debugPrint('📸 Compressing payment screenshot...');
        final compressedFile = await _compressImage(_paymentScreenshot!.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'paymentScreenshot',
            compressedFile.path,
            filename: 'payment_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      // 6. Send Request
      debugPrint('🚀 Sending Multipart Request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Increased timeout for uploads
      );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('📥 Response Code: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      final jsonResponse = response.body.isNotEmpty
          ? json.decode(response.body)
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          // Optimization: Trigger appointment fetch
          context.read<AppointmentProvider>().fetchAppointments();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.bookingSuccess),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } else {
        final l10n = AppLocalizations.of(context)!;
        String msg = jsonResponse['message'] ?? l10n.bookingFailed;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Booking Exception: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rescheduleFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isReschedule
              ? l10n.rescheduleAppointment
              : l10n.bookAppointment,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            // ✅ Show reschedule info banner
            if (widget.isReschedule) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.rescheduleBanner,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (selectedType == "Video Call")
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "* ",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: l10n.videoUploadWarning,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(
                          text: " *",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appointmentTypeLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildTypeOption(
                        'assets/icons/physical_visit.png',
                        "Physical Visit",
                        l10n.physicalVisit,
                        l10n.payAtClinic,
                      ),
                      const SizedBox(width: 15),
                      _buildTypeOption(
                        'assets/icons/video_call.png',
                        "Video Call",
                        l10n.videoCall,
                        l10n.onlinePayment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildWhiteCard(
              child: Consumer<DependentProvider>(
                builder: (context, provider, child) {
                  final dependents = provider.activeDependents;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bookAppointmentFor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildSelectForOption(
                        icon: Icons.person,
                        label: l10n.myself,
                        isSelected: selectedDependent == null,
                        onTap: () => setState(() => selectedDependent = null),
                      ),

                      if (dependents.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.orSelectDependent,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...dependents.map(
                          (dep) => _buildSelectForOption(
                            icon: dep.gender?.toLowerCase() == 'male'
                                ? Icons.boy
                                : Icons.girl,
                            label: dep.displayName,
                            subtitle: dep.age,
                            isSelected: selectedDependent?.id == dep.id,
                            onTap: () =>
                                setState(() => selectedDependent = dep),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-dependent').then((
                            _,
                          ) {
                            context.read<DependentProvider>().fetchDependents();
                          });
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF0D53C1),
                        ),
                        label: Text(
                          l10n.addNewDependent,
                          style: const TextStyle(
                            color: Color(0xFF0D53C1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? l10n.datePlaceholder
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(selectedDate!),
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Colors.grey
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (selectedDate != null)
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.availableTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTimeSlots(),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.describeSymptoms,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDashedInput(_symptomsController),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.uploadMedicalDocs,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickMedicalDocuments,
                    child: _buildUploadBox(
                      Icons.cloud_upload_outlined,
                      l10n.tapToUpload,
                    ),
                  ),
                  if (_medicalDocuments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        children: _medicalDocuments
                            .map((f) => Chip(label: Text(f.name)))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (selectedType == "Video Call")
              _buildWhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.uploadPaymentScreenshot,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickPaymentScreenshot,
                      child: _buildUploadBox(
                        Icons.cloud_upload_outlined,
                        l10n.tapToUploadPayment,
                      ),
                    ),
                    if (_paymentScreenshot != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Chip(label: Text(_paymentScreenshot!.name)),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? () {} : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D53C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        widget.isReschedule
                            ? l10n.confirmReschedule
                            : l10n.submitAppointmentRequest,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _buildTypeOption(
    String image,
    String typeKey,
    String displayTitle,
    String displaySubtitle,
  ) {
    bool isSelected = selectedType == typeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = typeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D53C1)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                image,
                color: isSelected ? const Color(0xFF0D53C1) : Colors.black54,
                width: 30,
                height: 30,
              ),
              const SizedBox(height: 5),
              Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF0D53C1) : Colors.black87,
                ),
              ),
              Text(
                displaySubtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectForOption({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D53C1).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D53C1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0D53C1) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0D53C1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                l10n.noTimeSlots,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: availableSlots.map((slot) => _buildTimeSlotCard(slot)).toList(),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected =
        selectedTimeSlot?.start == slot.start &&
        selectedTimeSlot?.end == slot.end;
    final isDisabled = slot.isBooked == true;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => selectedTimeSlot = slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : (isSelected ? const Color(0xFF0D53C1) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : (isSelected ? const Color(0xFF0D53C1) : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D53C1)
                      : Colors.grey[400]!,
                ),
              ),
              child: Text(
                _format24To12Hour(slot.start),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey
                      : (isSelected ? const Color(0xFF0D53C1) : Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                l10n.timeTo,
                style: TextStyle(
                  fontSize: 13,
                  color: isDisabled
                      ? Colors.grey
                      : (isSelected ? Colors.white : Colors.black54),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D53C1)
                      : Colors.grey[400]!,
                ),
              ),
              child: Text(
                _format24To12Hour(slot.end),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey
                      : (isSelected ? const Color(0xFF0D53C1) : Colors.black),
                ),
              ),
            ),
            if (isDisabled) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.booked,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _format24To12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  Widget _buildDashedInput(TextEditingController controller) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          hintText: l10n.symptomsHint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUploadBox(IconData icon, String label) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 25),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FBFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Column(
      children: [
        Icon(icon, color: Colors.black, size: 30),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
}
