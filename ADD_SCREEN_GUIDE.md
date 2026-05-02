# Adding Screens to the Navigation System

This project uses a config-driven navigation setup with Flutter's Navigator 2.0, Bloc, and a Material BottomNavigationBar. All screens are defined in `lib/navigation_config.dart`.

---

## 1. Add a Screen to the Bottom Navigation Bar

### a. Create the Screen Widget
Create a new file in `lib/pages/`, e.g. `my_page.dart`:
```dart
import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('My Page'));
  }
}
```

### b. Add the Screen to the Config
Open `lib/navigation_config.dart` and add a new entry to the `navScreens` list:
```dart
import 'pages/my_page.dart'; // at the top
// ...existing code...
NavScreenConfig(
  route: '/my',
  label: 'My',
  icon: Icons.star, // choose any icon
  builder: () => const MyPage(),
  inNavBar: true, // important!
),
```

### c. Update the AppPage Enum
In `lib/bloc/nav_bloc.dart`, add your new page to the enum:
```dart
enum AppPage { home, settings, profile, my }
```

That's it! The new screen will appear in the bottom navigation bar and be fully routable.

---

## 2. Add a Screen NOT in the Bottom Navigation Bar (but linkable)

### a. Create the Screen Widget
Create a new file in `lib/pages/`, e.g. `details_page.dart`:
```dart
import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Details Page'));
  }
}
```

### b. Add the Screen to the Config
In `lib/navigation_config.dart`, add:
```dart
import 'pages/details_page.dart'; // at the top
// ...existing code...
NavScreenConfig(
  route: '/details',
  label: 'Details',
  icon: Icons.info, // icon is optional for non-navbar
  builder: () => const DetailsPage(),
  inNavBar: false, // important!
),
```

### c. Link to the Page from Anywhere
From any widget (e.g. a button in HomePage):
```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DetailsPage()),
    );
  },
  child: Text('Go to Details'),
)
```

Or, if you want to use the navigation state/route system, you can add logic to your Bloc and navigation to support it.

---

## Notes
- All navigation logic, navbar, and route parsing are generated from `navigation_config.dart`.
- For new navbar pages, set `inNavBar: true`.
- For non-navbar pages, set `inNavBar: false` and link using `Navigator.push` or by updating navigation state.
- For deep linking, just add the route to the config.
