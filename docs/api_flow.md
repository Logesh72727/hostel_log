# Data Flow

1. Hardware (ESP32 + R307 + ESP32-CAM) authenticates student via fingerprint.
2. Upon successful match, hardware captures image and sends a log entry to Firestore `logs` collection with studentId, timestamp, type, and imageUrl.
3. Flutter app listens to Firestore changes and displays real-time logs.
4. Admin registers students via app, storing data in `students` collection.