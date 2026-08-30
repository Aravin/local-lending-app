DateTime dateTimeFromJson(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  throw FormatException('Cannot parse DateTime from $value');
}

String dateTimeToJson(DateTime value) => value.toIso8601String();

DateTime? optionalDateTimeFromJson(Object? value) {
  if (value == null) return null;
  return dateTimeFromJson(value);
}

String? optionalDateTimeToJson(DateTime? value) =>
    value == null ? null : dateTimeToJson(value);
