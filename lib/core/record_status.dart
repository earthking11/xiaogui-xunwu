enum RecordStatus { pending, recognizing, recognized, failed }

extension RecordStatusX on RecordStatus {
  String get storageValue {
    switch (this) {
      case RecordStatus.pending:
        return 'pending';
      case RecordStatus.recognizing:
        return 'recognizing';
      case RecordStatus.recognized:
        return 'recognized';
      case RecordStatus.failed:
        return 'failed';
    }
  }

  static RecordStatus fromStorageValue(String value) {
    switch (value) {
      case 'pending':
        return RecordStatus.pending;
      case 'recognizing':
        return RecordStatus.recognizing;
      case 'recognized':
        return RecordStatus.recognized;
      case 'failed':
        return RecordStatus.failed;
      default:
        throw ArgumentError('Unknown record status: $value');
    }
  }
}
