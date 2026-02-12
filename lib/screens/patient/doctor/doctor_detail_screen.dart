import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:aroggyapath/models/doctor_model.dart';
import 'package:aroggyapath/services/api_service.dart';
import 'package:aroggyapath/screens/patient/messages/patient_chat_screen.dart';
import 'book_appointment_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  List<dynamic> _reviews = [];
  double _avgRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorReviews();
  }

  /// ✅ Load doctor reviews from backend
  Future<void> _loadDoctorReviews() async {
    try {
      debugPrint('📥 Loading reviews for doctor: ${widget.doctor.id}');

      final response = await ApiService.get(
        '/api/v1/doctor-review/doctor/${widget.doctor.id}', // ✅ Fixed: removed 's'
        requiresAuth: false,
      );

      debugPrint('📥 Reviews API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        if (!mounted) return;
        setState(() {
          _reviews = data['items'] ?? [];
          _avgRating = (data['summary']?['avgRating'] ?? 0.0).toDouble();
          _totalReviews = data['summary']?['totalReviews'] ?? 0;
        });

        debugPrint('✅ Loaded ${_reviews.length} reviews, avg: $_avgRating');
      } else {
        debugPrint('❌ Reviews fetch failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasVideoCall =
        widget.doctor.isVideoCallAvailable; // ✅ Read from model

    debugPrint('📄 Details Screen: ${widget.doctor.fullName}');
    debugPrint('   - isVideoCallAvailable: $hasVideoCall');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: widget.doctor.image.startsWith('http')
                          ? Image.network(
                              widget.doctor.image,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              widget.doctor.image,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctor.fullName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.doctor.specialty,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),

                          // ✅ Video Call Badge (Cleaner Design)
                          if (hasVideoCall)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF2196F3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    color: Color(0xFF1976D2),
                                    size: 14,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    l10n.videoAvailable,
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFFA726),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Color(0xFFF57C00),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    l10n.inPersonOnly,
                                    style: const TextStyle(
                                      color: Color(0xFFE65100),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${widget.doctor.location} (${widget.doctor.distance})",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.orange,
                              ),
                              Text(
                                " ${_avgRating.toStringAsFixed(1)} ${l10n.reviewsCount(_totalReviews)}",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 35),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Bio
                Text(
                  l10n.bio,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.doctor.bio ??
                      "${widget.doctor.fullName} is a senior ${widget.doctor.specialty} with ${widget.doctor.experience} years of experience.",
                ),

                const SizedBox(height: 30),

                // Specialty & Degree
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.specialty,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildBulletItem(widget.doctor.specialty),
                        _buildBulletItem("General Medicine"),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.degree,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildBulletItem("MBBS, FCPS"),
                        _buildBulletItem("MD"),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // Fees
                Text(
                  "${l10n.fees}: ${widget.doctor.fees?['amount'] ?? 500} ${l10n.dzd}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // Visiting hours
                Text(
                  _getVisitingHours(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Message Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () => _openChatWithDoctor(context),
                    icon: const Icon(
                      Icons.message_outlined,
                      color: Color(0xFF6C5CE7),
                    ),
                    label: Text(
                      l10n.messageDoctor,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF6C5CE7),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Book Now Button
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.doctor.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.invalidDoctor)),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookAppointmentScreen(doctor: widget.doctor),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D53C1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      l10n.bookNow,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "• ",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(text, style: const TextStyle(fontSize: 17)),
        ],
      ),
    );
  }

  String _getVisitingHours() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.doctor.weeklySchedule == null ||
        widget.doctor.weeklySchedule!.isEmpty) {
      return '${l10n.visitingHours}: ${l10n.notSet}';
    }

    List<String> activeDays = [];
    for (var schedule in widget.doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        activeDays.add(schedule.day.substring(0, 3));
      }
    }

    if (activeDays.isEmpty) {
      return '${l10n.visitingHours}: ${l10n.notSet}';
    }

    if (activeDays.length <= 3) {
      return '${l10n.visitingHours}: ${activeDays.join(', ')}';
    } else {
      return '${l10n.visitingHours}: ${activeDays.first}-${activeDays.last}';
    }
  }

  void _openChatWithDoctor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doctorId = widget.doctor.id;

      if (doctorId.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.doctorIdNotFound),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('🔍 Creating/Getting chat with doctor ID: $doctorId');

      final result = await ApiService.createOrGetChat(userId: doctorId);

      if (!context.mounted) return;
      Navigator.pop(context);

      debugPrint('📥 Chat result: $result');

      if (result['success'] == true) {
        final chatData = result['data'];
        final chatId = (chatData['id'] ?? chatData['_id'])?.toString();

        if (chatId == null || chatId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedCreateChat),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        debugPrint('✅ Chat ID: $chatId');

        // Participants is now List<String> (UUIDs), so we can't get avatar from it directly.
        // We already have the doctor's details in widget.doctor.
        String? doctorAvatar = widget.doctor.image;
        if (!doctorAvatar.startsWith('http')) {
          doctorAvatar = null;
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: chatId,
                doctorName: widget.doctor.fullName,
                doctorAvatar:
                    doctorAvatar ??
                    (widget.doctor.image.startsWith('http')
                        ? widget.doctor.image
                        : null),
                doctorId: doctorId,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? l10n.failedOpenChat),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('❌ Error opening chat: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
