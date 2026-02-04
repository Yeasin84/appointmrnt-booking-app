import 'package:flutter/material.dart';
import 'package:aroggyapath/models/appointment_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAppointmentListPdf(
    List<AppointmentModel> appointments,
    String doctorName, {
    DateTimeRange? dateRange, // Optional date range
  }) async {
    final pdf = pw.Document();

    // Sort appointments by date
    appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildHeader(doctorName, dateRange),
            pw.SizedBox(height: 20),
            _buildAppointmentTable(appointments),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Appointments_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static pw.Widget _buildHeader(String doctorName, DateTimeRange? dateRange) {
    String dateText = DateFormat('MMMM d, y').format(DateTime.now());
    if (dateRange != null) {
      final start = DateFormat('MMM d, y').format(dateRange.start);
      final end = DateFormat('MMM d, y').format(dateRange.end);
      dateText = '$start - $end';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Appointment Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Doctor: $doctorName', style: const pw.TextStyle(fontSize: 16)),
        pw.Text('Date: $dateText', style: const pw.TextStyle(fontSize: 14)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildAppointmentTable(List<AppointmentModel> appointments) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Time', 'Patient', 'Type', 'Status', 'Symptoms'],
      data: appointments.map((apt) {
        return [
          DateFormat('MMM d').format(apt.appointmentDate),
          apt.appointmentTime,
          apt.patientName ?? 'Unknown',
          apt.appointmentType ?? 'N/A',
          apt.status.toUpperCase(),
          apt.symptoms ?? '-',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      cellPadding: const pw.EdgeInsets.all(8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerLeft,
      },
    );
  }
}
