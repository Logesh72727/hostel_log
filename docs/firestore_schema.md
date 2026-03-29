# Firestore Schema

## students collection
- `id` (document ID): auto-generated string
- `name`: string
- `room`: string
- `fingerprintId`: number (1-1000)
- `photoUrl`: string (optional)
- `createdAt`: timestamp

## logs collection
- `id` (document ID): auto-generated string
- `studentId`: string (reference to student document ID)
- `timestamp`: timestamp
- `type`: string ('entry' or 'exit')
- `imageUrl`: string (optional)