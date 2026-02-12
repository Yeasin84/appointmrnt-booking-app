import 'package:aroggyapath/screens/doctor/navigation/doctor_main_navigation.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'package:aroggyapath/providers/appointment_provider.dart';
import 'package:aroggyapath/screens/doctor/appointments/session_holder_screen.dart';
import 'package:aroggyapath/services/pdf_service.dart';
import 'package:aroggyapath/providers/user_provider.dart';
import 'widgets/pending_appointment_card.dart';
import 'widgets/confirmed_appointment_card.dart';
import 'widgets/completed_appointment_card.dart';
import 'widgets/appointment_details_sheet.dart';
import 'package:aroggyapath/utils/colors.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String selectedTab = "Pending";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimary(context),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorMainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Appointment Management',
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.indigo),
            tooltip: 'Export Report',
            onPressed: () async => _handleExport(),
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Manage your Video and physical\nConsultations",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tab Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton(
                        l10n.pending,
                        provider.pendingAppointments.length,
                      ),
                      const SizedBox(width: 5),
                      _buildTabButton(
                        l10n.confirmed,
                        provider.acceptedAppointments.length,
                      ),
                      const SizedBox(width: 5),
                      _buildTabButton(
                        l10n.completed,
                        provider.completedAppointments.length,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ),

              // Content
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleExport() async {
    final provider = context.read<AppointmentProvider>();
    final allAppointments = [
      ...provider.pendingAppointments,
      ...provider.acceptedAppointments,
      ...provider.completedAppointments,
    ];

    if (allAppointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No appointments to export')),
      );
      return;
    }

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Appointment Date Range',
      confirmText: 'Export PDF',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange == null) return;

    final filteredAppointments = allAppointments.where((apt) {
      final aptDate = DateTime(
        apt.appointmentDate.year,
        apt.appointmentDate.month,
        apt.appointmentDate.day,
      );
      return aptDate.isAtSameMomentAs(pickedRange.start) ||
          aptDate.isAtSameMomentAs(pickedRange.end) ||
          (aptDate.isAfter(pickedRange.start) &&
              aptDate.isBefore(pickedRange.end));
    }).toList();

    if (!mounted) return;

    if (filteredAppointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No appointments found in this date range'),
        ),
      );
      return;
    }

    String doctorName = 'Doctor';
    try {
      doctorName = context.read<UserProvider>().user?.fullName ?? 'Doctor';
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }

    await PdfService.generateAppointmentListPdf(
      filteredAppointments,
      doctorName,
      dateRange: pickedRange,
    );
  }

  Widget _buildContent(AppointmentProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchAppointments(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    List<AppointmentModel> appointments;
    if (selectedTab == l10n.pending) {
      appointments = provider.pendingAppointments;
    } else if (selectedTab == l10n.confirmed) {
      appointments = provider.acceptedAppointments;
    } else {
      appointments = provider.completedAppointments;
    }

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noAppointments(selectedTab),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchAppointments(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          if (selectedTab == l10n.pending) {
            return PendingAppointmentCard(
              appointment: appointment,
              provider: provider,
              onShowDetails: _showAppointmentDetails,
              onAccept: _handleAccept,
              onCancel: _handleCancel,
            );
          } else if (selectedTab == l10n.confirmed) {
            return ConfirmedAppointmentCard(
              appointment: appointment,
              provider: provider,
              onShowDetails: _showAppointmentDetails,
              onCancel: _handleCancel,
              onStartSession: _handleStartSession,
            );
          } else {
            return CompletedAppointmentCard(appointment: appointment);
          }
        },
      ),
    );
  }

  Widget _buildTabButton(String title, int count) {
    bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => AppointmentDetailsSheet(
          appointment: appointment,
          scrollController: controller,
        ),
      ),
    );
  }

  void _handleAccept(String appointmentId, AppointmentProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await provider.acceptAppointment(appointmentId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.appointmentAccepted : l10n.failedAccept,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleCancel(String appointmentId, AppointmentProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelAppointment),
        content: Text(l10n.confirmCancel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                final success = await provider.cancelAppointment(appointmentId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? l10n.appointmentCancelled : l10n.failedCancel,
                      ),
                      backgroundColor: success ? Colors.orange : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleStartSession(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHolderScreen(appointment: appointment),
      ),
    ).then((result) {
      if (result == true) {
        if (!mounted) return;
        context.read<AppointmentProvider>().fetchAppointments();
      }
    });
  }
}
