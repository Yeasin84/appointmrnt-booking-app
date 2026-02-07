import 'package:flutter/material.dart';

Widget statusBadge(String text, Color bg, Color txt) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: txt, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}

Widget smallIconText(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFF1664CD)),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1B2C49),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget actionBtn(String label, Color bg, Color txt, VoidCallback? onTap) {
  return SizedBox(
    height: 45,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: txt,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ),
  );
}
