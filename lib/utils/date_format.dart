const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Such as "Nov 22, 2026, 3:05 PM".
String formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final half = date.hour < 12 ? 'AM' : 'PM';
  return '${_months[date.month - 1]} ${date.day}, ${date.year}, '
      '$hour:$minute $half';
}
