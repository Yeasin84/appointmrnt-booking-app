import 'package:aroggyapath/services/earnings_service.dart';
import 'package:flutter/material.dart';
import 'package:aroggyapath/l10n/app_localizations.dart';

class EarningOverviewScreen extends StatefulWidget {
  const EarningOverviewScreen({super.key});

  @override
  State<EarningOverviewScreen> createState() => _EarningOverviewScreenState();
}

class _EarningOverviewScreenState extends State<EarningOverviewScreen> {
  final EarningService _earningService = EarningService();

  String selectedPeriod = 'weekly';
  bool isLoading = false;
  String? error;

  // Initial State Data
  Map<String, dynamic> earningsData = {
    'totalEarnings': 0.0,
    'totalAppointments': 0,
    'physical': {'earnings': 0.0, 'count': 0},
    'video': {'earnings': 0.0, 'count': 0},
    'weeklyByWeekday': null,
  };

  @override
  void initState() {
    super.initState();
    // স্ক্রিন লোড হওয়ার সাথে সাথে ডাটা ফেচ করবে
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    // mounted চেক করা হয়েছে যাতে স্ক্রিন অফ থাকলে স্টেট আপডেট না হয়
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await _earningService.getEarningsOverview(
        view: selectedPeriod,
      );

      // কনসোলে চেক করার জন্য প্রিন্ট (প্রয়োজনে রিমুভ করতে পারেন)
      debugPrint('📥 Raw Response: $response');

      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            earningsData = response['data'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            error =
                response['message'] ??
                AppLocalizations.of(context)!.failedFetchEarnings;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '${AppLocalizations.of(context)!.connectionError}: $e';
          isLoading = false;
        });
      }
    }
  }

  void _updatePeriod(String period) {
    if (selectedPeriod == period) return; // একই পিরিয়ড হলে লোড করার দরকার নেই
    setState(() {
      selectedPeriod = period;
    });
    _fetchEarnings();
  }

  String _getLocalizedPeriod(String period) {
    final l10n = AppLocalizations.of(context)!;
    switch (period) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'monthly':
        return l10n.monthly;
      default:
        return period.substring(0, 1).toUpperCase() + period.substring(1);
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.earningOverview,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchEarnings,
        color: const Color(0xFF2D5AF0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.trackIncomeSubtitle,
                style: const TextStyle(color: Colors.black87, fontSize: 15),
              ),
              const SizedBox(height: 25),

              // Period Selector Tabs
              Container(
                padding: const EdgeInsets.only(bottom: 20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildToggleButton('daily'),
                    _buildToggleButton('weekly'),
                    _buildToggleButton('monthly'),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF2D5AF0)),
                  ),
                )
              else if (error != null)
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5AF0),
                        ),
                        onPressed: _fetchEarnings,
                        child: Text(
                          AppLocalizations.of(context)!.retry,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildEarningsContent(),

              const SizedBox(height: 50), // নীচ থেকে একটু স্পেস রাখা
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsContent() {
    // num টাইপ ব্যবহার করা হয়েছে যাতে int বা double দুইটাই হ্যান্ডেল করা যায়
    final total = (earningsData['totalEarnings'] ?? 0);
    final physicalEarnings = (earningsData['physical']?['earnings'] ?? 0);
    final physicalCount = (earningsData['physical']?['count'] ?? 0);
    final videoEarnings = (earningsData['video']?['earnings'] ?? 0);
    final videoCount = (earningsData['video']?['count'] ?? 0);
    final totalAppts = (earningsData['totalAppointments'] ?? 0);
    final weeklyData = earningsData['weeklyByWeekday'];

    return Column(
      children: [
        // Total Earning Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                // backgroundColor: const Color.fromARGB(255, 248, 248, 3),
                radius: 25,
                child: Image.asset(
                  'assets/images/algerian.png',
                  width: 50,
                  height: 50,
                  // color: Colors.white,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalEarning,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '${total.toDouble().toStringAsFixed(2)}', // DZD  Display
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2C49),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.appointmentsCount(totalAppts),
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Type Breakdown Cards
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                AppLocalizations.of(context)!.physical,
                '${physicalEarnings.toDouble().toStringAsFixed(1)}',
                AppLocalizations.of(context)!.sessionsCount(physicalCount),
                Icons.location_on_outlined,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildSmallCard(
                AppLocalizations.of(context)!.video,
                videoEarnings.toDouble().toStringAsFixed(1),
                AppLocalizations.of(context)!.sessionsCount(videoCount),
                Icons.videocam_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        // Bar Chart (for weekly)
        if (selectedPeriod == 'weekly' && weeklyData != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.weeklyPerformance,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 25),
                CustomBarChart(
                  chartData: List<num>.from(
                    weeklyData['values'] ?? [0, 0, 0, 0, 0, 0, 0],
                  ),
                  labels: List<String>.from(
                    weeklyData['labels'] ?? ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildToggleButton(String period) {
    bool isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () => _updatePeriod(period),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5AF0) : const Color(0xFFF1F4FF),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          _getLocalizedPeriod(period),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1B2C49),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    String title,
    String amount,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Icon + Title Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1F4FF),
                child: Icon(icon, size: 28, color: const Color(0xFF2D5AF0)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2C49),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 💰 Amount with money icon
          Row(
            children: [
              const Icon(Icons.money, size: 18, color: Color(0xFF2D5AF0)),
              const SizedBox(width: 8),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CustomBarChart extends StatelessWidget {
  final List<num> chartData;
  final List<String> labels;

  const CustomBarChart({
    super.key,
    required this.chartData,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // সর্বোচ্চ ভ্যালু বের করা যাতে চার্ট হাইট ঠিক থাকে
    num maxVal = chartData.isEmpty
        ? 1
        : chartData.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(chartData.length, (index) {
        double barHeight =
            (chartData[index] / maxVal) * 100; // ১০০ পিক্সেল স্কেলে
        return Column(
          children: [
            Text(
              '${chartData[index].toInt()}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 14,
              height: barHeight.clamp(4.0, 100.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C77F5), Color(0xFF2D5AF0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels[index],
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }),
    );
  }
}
