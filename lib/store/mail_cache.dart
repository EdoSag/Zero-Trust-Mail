import '../protocol/mail_backend.dart';

/// The phone's copy of mail: folders, message lists and the bodies already
/// opened, so the app works offline and opens instantly.
///
/// This is the shape every screen reads from. [MemoryMailCache] keeps it in
/// memory; the encrypted on-disk cache (one SQLite file per account, opened
/// with a key from the vault) implements the same interface.
abstract interface class MailCache {
  Future<List<MailFolder>> folders(String accountId);
  Future<void> putFolders(String accountId, List<MailFolder> folders);

  /// Newest first.
  Future<List<MessageSummary>> messages(
    String accountId,
    String folderId, {
    int limit = 50,
    int offset = 0,
  });

  /// The marker from the last [applyChanges], to ask the server what is new.
  Future<String?> folderState(String accountId, String folderId);

  Future<void> applyChanges(
    String accountId,
    String folderId,
    FolderChanges changes,
  );

  Future<MessageBody?> body(String accountId, String folderId, String id);
  Future<void> putBody(
    String accountId,
    String folderId,
    String id,
    MessageBody body,
  );

  /// Forgets everything kept for [accountId] (the account was removed).
  Future<void> clearAccount(String accountId);
}

class MemoryMailCache implements MailCache {
  final _folders = <String, List<MailFolder>>{};
  final _messages = <String, Map<String, MessageSummary>>{};
  final _states = <String, String>{};
  final _bodies = <String, MessageBody>{};

  static String _folderKey(String accountId, String folderId) =>
      '$accountId\u0000$folderId';
  static String _messageKey(String accountId, String folderId, String id) =>
      '$accountId\u0000$folderId\u0000$id';

  @override
  Future<List<MailFolder>> folders(String accountId) async =>
      List.unmodifiable(_folders[accountId] ?? const []);

  @override
  Future<void> putFolders(String accountId, List<MailFolder> folders) async {
    _folders[accountId] = [...folders];
  }

  @override
  Future<List<MessageSummary>> messages(
    String accountId,
    String folderId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final all = [
      ...?_messages[_folderKey(accountId, folderId)]?.values,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return all.skip(offset).take(limit).toList();
  }

  @override
  Future<String?> folderState(String accountId, String folderId) async =>
      _states[_folderKey(accountId, folderId)];

  @override
  Future<void> applyChanges(
    String accountId,
    String folderId,
    FolderChanges changes,
  ) async {
    final key = _folderKey(accountId, folderId);
    final messages = _messages.putIfAbsent(key, () => {});
    if (changes.resync) {
      for (final id in messages.keys) {
        _bodies.remove(_messageKey(accountId, folderId, id));
      }
      messages.clear();
    }
    for (final id in changes.removedIds) {
      messages.remove(id);
      _bodies.remove(_messageKey(accountId, folderId, id));
    }
    for (final m in changes.upserted) {
      messages[m.id] = m;
    }
    _states[key] = changes.state;
  }

  @override
  Future<MessageBody?> body(
    String accountId,
    String folderId,
    String id,
  ) async => _bodies[_messageKey(accountId, folderId, id)];

  @override
  Future<void> putBody(
    String accountId,
    String folderId,
    String id,
    MessageBody body,
  ) async {
    _bodies[_messageKey(accountId, folderId, id)] = body;
  }

  @override
  Future<void> clearAccount(String accountId) async {
    final prefix = '$accountId\u0000';
    _folders.remove(accountId);
    _messages.removeWhere((k, _) => k.startsWith(prefix));
    _states.removeWhere((k, _) => k.startsWith(prefix));
    _bodies.removeWhere((k, _) => k.startsWith(prefix));
  }
}
