class AiMessageModel {
  final String id;
  final String sender; // 'user' or 'concierge'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final List<String> citations;

  const AiMessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.citations = const [],
  });

  AiMessageModel copyWith({
    String? id,
    String? sender,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    List<String>? citations,
  }) {
    return AiMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      citations: citations ?? this.citations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AiMessageModel.fromMap(Map<String, dynamic> map) {
    return AiMessageModel(
      id: map['id'] as String,
      sender: map['sender'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isStreaming: false,
      citations: const [],
    );
  }
}
