import 'package:flutter/foundation.dart';

/// What a folder is for, so the app can show Inbox, Sent and the rest in
/// the same places whatever the server calls them.
enum FolderRole { inbox, drafts, sent, archive, junk, trash, all, other }

@immutable
class MailFolder {
  const MailFolder({
    required this.id,
    required this.name,
    this.role = FolderRole.other,
    this.parentId,
    this.unread = 0,
    this.total = 0,
  });

  /// The server's id: the IMAP path, or the JMAP mailbox id.
  final String id;
  final String name;
  final FolderRole role;
  final String? parentId;
  final int unread;
  final int total;
}

@immutable
class MailAddress {
  const MailAddress(this.email, [this.name = '']);
  final String email;
  final String name;

  String get label => name.isEmpty ? email : name;

  @override
  bool operator ==(Object other) =>
      other is MailAddress && other.email == email && other.name == name;

  @override
  int get hashCode => Object.hash(email, name);
}

/// A message as it appears in a list: headers only, no body.
@immutable
class MessageSummary {
  const MessageSummary({
    required this.id,
    required this.folderId,
    required this.from,
    required this.subject,
    required this.date,
    this.to = const [],
    this.cc = const [],
    this.preview = '',
    this.threadId,
    this.messageIdHeader,
    this.references = const [],
    this.seen = false,
    this.flagged = false,
    this.answered = false,
    this.hasAttachments = false,
    this.size = 0,
  });

  /// The server's id inside [folderId]: the IMAP UID, or the JMAP email id.
  final String id;
  final String folderId;
  final MailAddress from;
  final List<MailAddress> to;
  final List<MailAddress> cc;
  final String subject;
  final DateTime date;

  /// First words of the body, when the server gives them.
  final String preview;

  /// The server's conversation id (JMAP). IMAP conversations are built on
  /// the phone from [messageIdHeader] and [references].
  final String? threadId;
  final String? messageIdHeader;
  final List<String> references;
  final bool seen;
  final bool flagged;
  final bool answered;
  final bool hasAttachments;
  final int size;
}

@immutable
class AttachmentInfo {
  const AttachmentInfo({
    required this.partId,
    required this.fileName,
    required this.mimeType,
    required this.size,
    this.inline = false,
  });

  final String partId;
  final String fileName;
  final String mimeType;
  final int size;

  /// Shown inside the message (an embedded picture), not as a file.
  final bool inline;
}

/// The readable parts of a message. Attachments are fetched one by one.
@immutable
class MessageBody {
  const MessageBody({this.text, this.html, this.attachments = const []});
  final String? text;
  final String? html;
  final List<AttachmentInfo> attachments;
}

/// What changed in a folder since the app last looked.
@immutable
class FolderChanges {
  const FolderChanges({
    required this.state,
    this.upserted = const [],
    this.removedIds = const [],
    this.resync = false,
  });

  /// Opaque marker to pass to the next `changes` call.
  final String state;

  /// New messages and messages whose flags changed.
  final List<MessageSummary> upserted;
  final List<String> removedIds;

  /// The server can't say what changed (the marker is too old): drop the
  /// folder's cache and take [upserted] as its whole content.
  final bool resync;
}

@immutable
class OutgoingMessage {
  const OutgoingMessage({
    required this.from,
    required this.to,
    required this.subject,
    this.cc = const [],
    this.bcc = const [],
    this.text = '',
    this.html,
    this.inReplyTo,
    this.references = const [],
    this.attachments = const [],
  });

  final MailAddress from;
  final List<MailAddress> to;
  final List<MailAddress> cc;
  final List<MailAddress> bcc;
  final String subject;
  final String text;
  final String? html;
  final String? inReplyTo;
  final List<String> references;
  final List<OutgoingAttachment> attachments;
}

@immutable
class OutgoingAttachment {
  const OutgoingAttachment({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

/// Why a mail server call failed, in terms the app can act on.
enum MailFailure {
  /// No connection, or the server didn't answer. Try again later.
  offline,

  /// The server refused the name or password. Ask for it again.
  signIn,

  /// The server's certificate can't be trusted. Never continue.
  certificate,

  /// The server answered with something else.
  server,
}

class MailException implements Exception {
  const MailException(this.failure, [this.detail = '']);
  final MailFailure failure;

  /// The server's own words, for the "details" line. Never a password.
  final String detail;

  @override
  String toString() => 'MailException(${failure.name}: $detail)';
}

/// One account's server, the same for IMAP + SMTP and for JMAP. The app's
/// screens, cache and sync only ever see this interface.
///
/// Every method throws [MailException] on failure.
abstract interface class MailBackend {
  /// Signs in and checks the server is usable. Called when an account is
  /// added and before the first sync.
  Future<void> connect();

  Future<List<MailFolder>> folders();

  /// What changed in [folderId] since [sinceState] (null for a first
  /// look, which returns the newest [limit] messages).
  Future<FolderChanges> changes(
    String folderId, {
    String? sinceState,
    int limit = 50,
  });

  /// Older messages than [beforeId], for scrolling back.
  Future<List<MessageSummary>> older(
    String folderId, {
    required String beforeId,
    int limit = 50,
  });

  Future<MessageBody> body(String folderId, String messageId);

  Future<Uint8List> attachment(
    String folderId,
    String messageId,
    String partId,
  );

  Future<void> setSeen(String folderId, List<String> ids, bool seen);
  Future<void> setFlagged(String folderId, List<String> ids, bool flagged);

  Future<void> move(String fromFolderId, List<String> ids, String toFolderId);

  /// Deletes for good. Moving to Trash is [move].
  Future<void> expunge(String folderId, List<String> ids);

  /// Sends [message] and stores a copy in the Sent folder when the server
  /// doesn't do that itself.
  Future<void> send(OutgoingMessage message);

  Future<void> close();
}
