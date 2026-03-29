import 'package:intl/intl.dart';

String formatTimestamp(DateTime timestamp) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
}
