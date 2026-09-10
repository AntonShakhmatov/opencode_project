class ChatMessage {
  final String id;
  final String jobId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'],
      jobId: json['jobId'],
      senderId: json['senderId'],
      senderName: sender?['name'] ?? 'Unknown',
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}