class LanNotification {
  LanNotification({
    required this.title,
    required this.content,
    required this.recipientAddress,
    required this.id,
  });

  /// Identifies json notification message.
  final String type = 'notif';

  /// Title of the notif.
  /// Shown to user.
  final String title;

  /// Content of the notif.
  /// Shown to user.
  final String content;

  /// Recipient can be single address:
  /// 192.168.100.1
  ///
  /// or multiple: 192.168.100.1, 192.168.100.2
  ///
  /// or all: *
  final List<String> recipientAddress;

  /// id identifier of notif.
  final int id;

  factory LanNotification.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'notif') {
      throw Exception('Invalid notification type');
    }
    return LanNotification(
      title: json['title'] as String,
      content: json['content'] as String,
      recipientAddress: List<String>.from(json['recipient'] as List),
      id: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'title': title,
        'content': content,
        'recipient': recipientAddress,
        'id': id,
      };
}

class LanNotificationRequest extends LanNotification {
  LanNotificationRequest(
      {required super.title,
      required super.content,
      required super.recipientAddress,
      required super.id});

  factory LanNotificationRequest.fromJson(Map<String, dynamic> json) =>
      LanNotificationRequest(
        title: json['title'] as String,
        content: json['content'] as String,
        id: json['id'] as int,
        recipientAddress: List.from(json['recipient']),
      );
}
