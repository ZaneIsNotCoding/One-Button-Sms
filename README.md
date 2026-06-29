# One Button SMS

One Button SMS is a Flutter prototype for an emergency alert and notification system. It focuses on a simple, accessible flow:

1. Log in
2. Review contacts and message
3. Press one emergency button
4. Confirm the alert
5. Record alert history

## What is included

- Cross-platform Flutter UI
- Login and registration screens
- Emergency dashboard
- One-tap alert confirmation
- Emergency contact management
- Custom emergency messages
- Optional location text toggle
- SMS activity history
- Organization-style admin dashboard mockup

## Running in Android Studio

Flutter is not installed in this workspace environment, so the app could not be executed here. To run it locally:

```bash
flutter pub get
flutter run
```

If Android or iOS platform folders are missing in your local checkout, run:

```bash
flutter create .
flutter pub get
flutter run
```

## Real SMS integration note

This prototype simulates SMS sending and saves logs in app state. For production, connect `AlertService` in `lib/main.dart` to an SMS provider such as Twilio, Semaphore, Vonage, or to an Android-specific SMS permission flow.
