/// 会话实体类
class Conversation {
  final String title;
  final String avatar;
  final String lastMsg;
  final String time;

  const Conversation({
    required this.title,
    required this.avatar,
    required this.lastMsg,
    required this.time,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      title: json['title'] as String,
      avatar: json['avatar'] as String,
      lastMsg: json['last_msg'] as String,
      time: json['time'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'avatar': avatar,
    'last_msg': lastMsg,
    'time': time,
  };

  @override
  String toString() => 'Conversation($title, $lastMsg, $time)';
}
