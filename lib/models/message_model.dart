class Message {
  final String id;
  final String doctorName;
  final String doctorImage;
  final String lastMessage;
  final String time;
  final bool isRead;

  Message({
    required this.id,
    required this.doctorName,
    required this.doctorImage,
    required this.lastMessage,
    required this.time,
    required this.isRead,
  });
}