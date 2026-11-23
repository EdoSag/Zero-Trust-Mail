import 'package:flutter/foundation.dart';

/// How the app talks to an account's server.
enum MailProtocol {
  /// IMAP for reading, SMTP for sending. Works with every provider.
  imap,

  /// JMAP: one connection for reading, sending and push.
  jmap,

  /// An encrypted `@ztmail.me` mailbox (JMAP, mail stored encrypted with
  /// the account's own key).
  ztMailbox,
}

/// How a connection is secured. Plain connections are never offered.
enum MailSecurity {
  /// TLS from the first byte (IMAP 993, SMTP 465, JMAP 443).
  tls,

  /// Starts plain and must upgrade before signing in (SMTP 587, IMAP 143).
  startTls,
}

/// One server an account connects to.
@immutable
class MailServer {
  const MailServer({
    required this.host,
    required this.port,
    this.security = MailSecurity.tls,
  });

  final String host;
  final int port;
  final MailSecurity security;

  Map<String, Object?> toJson() => {
    'host': host,
    'port': port,
    'security': security.name,
  };

  static MailServer? fromJson(Object? json) {
    if (json is! Map) return null;
    final host = json['host'];
    final port = json['port'];
    if (host is! String || host.isEmpty || port is! num) return null;
    return MailServer(
      host: host,
      port: port.toInt(),
      security:
          MailSecurity.values.asNameMap()[json['security']] ?? MailSecurity.tls,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MailServer &&
      other.host == host &&
      other.port == port &&
      other.security == security;

  @override
  int get hashCode => Object.hash(host, port, security);
}

/// A mail account as it syncs between the user's devices: who and where,
/// never the password. Secrets stay on each phone (`CredentialStore`).
@immutable
class MailAccount {
  const MailAccount({
    required this.id,
    required this.email,
    required this.protocol,
    required this.incoming,
    this.outgoing,
    this.displayName = '',
    this.username = '',
    this.order = 0,
  });

  final String id;

  /// The address mail is sent from.
  final String email;

  /// The name recipients see. Empty shows the address alone.
  final String displayName;

  final MailProtocol protocol;

  /// IMAP server, or the JMAP endpoint host.
  final MailServer incoming;

  /// SMTP server. Null for JMAP, which sends over the same connection.
  final MailServer? outgoing;

  /// Sign-in name when it differs from [email]. Empty means [email].
  final String username;

  /// Position in the account list.
  final int order;

  String get signInName => username.isEmpty ? email : username;

  /// What the account is called in lists.
  String get label => displayName.isEmpty ? email : displayName;

  MailAccount copyWith({
    String? email,
    String? displayName,
    MailProtocol? protocol,
    MailServer? incoming,
    MailServer? outgoing,
    String? username,
    int? order,
  }) => MailAccount(
    id: id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    protocol: protocol ?? this.protocol,
    incoming: incoming ?? this.incoming,
    outgoing: outgoing ?? this.outgoing,
    username: username ?? this.username,
    order: order ?? this.order,
  );

  /// Every field is written (null when unset), so an older app version
  /// keeps fields it doesn't know about.
  Map<String, Object?> toJson() => {
    'email': email,
    'displayName': displayName,
    'protocol': protocol.name,
    'incoming': incoming.toJson(),
    'outgoing': outgoing?.toJson(),
    'username': username,
    'order': order,
  };

  /// Null when the item can't be read as an account (damaged, or from a
  /// version with a protocol this one doesn't know).
  static MailAccount? fromJson(String id, Map<String, Object?> json) {
    final email = json['email'];
    final protocol = MailProtocol.values.asNameMap()[json['protocol']];
    final incoming = MailServer.fromJson(json['incoming']);
    if (email is! String || protocol == null || incoming == null) return null;
    return MailAccount(
      id: id,
      email: email,
      displayName: json['displayName'] as String? ?? '',
      protocol: protocol,
      incoming: incoming,
      outgoing: MailServer.fromJson(json['outgoing']),
      username: json['username'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Whether [value] looks like an email address. Deliberately loose: the
/// server is the judge, this only catches typing slips.
bool looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s.]+$').hasMatch(value.trim());

/// Whether [value] can be a server name: letters, digits, dots and dashes.
bool looksLikeHost(String value) => RegExp(
  r'^(?=.{1,253}$)([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z0-9-]{2,63}$',
).hasMatch(value.trim());
