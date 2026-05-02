import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/nav_bloc.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/panic_bloc/panic_bloc.dart';
import 'bloc/onboarding_bloc.dart';
import 'widgets/panic_button.dart';
import 'theme.dart';
import 'navigation_config.dart';
import 'pages/onboarding_page.dart';
import 'pages/settings_page.dart';
import 'pages/placeholder_page.dart';
import 'pages/navigation_page.dart';

class MainTabPage<T> extends Page<T> {
  final Widget child;

  const MainTabPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return child;
          },
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
    );
  }
}

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavBloc()),
        BlocProvider(create: (context) => SettingsBloc()),
        BlocProvider(create: (context) => PanicBloc()),
        BlocProvider(create: (context) => OnboardingBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppRouterDelegate _routerDelegate;
  final AppRouteInformationParser _routeInformationParser =
      AppRouteInformationParser();

  @override
  void initState() {
    super.initState();
    _routerDelegate = AppRouterDelegate(
      navBloc: context.read<NavBloc>(),

      initialPath: AppPath.fromScreen(
        navScreens.firstWhere((s) => s.route == '/placeholder'),
      ),
    );

    context.read<OnboardingBloc>().add(CheckOnboardingStatus());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state.showOnboarding) {
          return MaterialApp(
            theme: appTheme,
            // builder: (context, child) => AccessibilityTools(child: child),
            home: OnboardingPage(
              onFinish: () {
                context.read<OnboardingBloc>().add(CompleteOnboarding());
              },
            ),
            debugShowCheckedModeBanner: false,
          );
        } else {
          return MaterialApp.router(
            theme: appTheme,
            // builder: (context, child) => AccessibilityTools(child: child),
            routerDelegate: _routerDelegate,
            routeInformationParser: _routeInformationParser,
            backButtonDispatcher: RootBackButtonDispatcher(),
            debugShowCheckedModeBanner: false,
          );
        }
      },
    );
  }
}

NavScreenConfig? navScreenConfigFromRoute(String? route) {
  if (route == null) return null;
  try {
    return navScreens.firstWhere((screen) => screen.route == route);
  } catch (e) {
    return null;
  }
}

class AppPath {
  final NavScreenConfig? currentScreen;
  final List<String> subPageStack;

  AppPath.fromScreen(this.currentScreen, [this.subPageStack = const []]);

  factory AppPath.fromNavState(NavState navState) {
    String route;
    switch (navState.mainPage) {
      case AppPage.placeholder:
        route = '/placeholder';
        break;
      case AppPage.settings:
        route = '/settings';
        break;
      case AppPage.navigation:
        route = '/navigation';
        break;
    }
    final mainScreenConfig = navScreenConfigFromRoute(route);
    return AppPath.fromScreen(mainScreenConfig, navState.subPageStack);
  }

  String? get routePath {
    if (currentScreen == null) return '/';
    String path = currentScreen!.route;
    if (subPageStack.isNotEmpty) {
      path += '/${subPageStack.join('/')}';
    }
    return path;
  }

  static AppPath parse(String uri) {
    final parts = Uri.parse(uri).pathSegments;
    if (parts.isEmpty) {
      return AppPath.fromScreen(
        navScreens.firstWhere((s) => s.route == '/placeholder'),
      );
    }
    final mainRoute = '/${parts.first}';
    final screenConfig = navScreenConfigFromRoute(mainRoute);

    if (screenConfig != null) {
      final subStack = parts.length > 1 ? parts.sublist(1) : <String>[];
      return AppPath.fromScreen(screenConfig, subStack);
    }

    return AppPath.fromScreen(
      navScreens.firstWhere((s) => s.route == '/placeholder'),
    );
  }
}

class AppRouterDelegate extends RouterDelegate<AppPath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppPath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;
  final NavBloc navBloc;
  AppPath _currentPath;

  AppRouterDelegate({required this.navBloc, required AppPath initialPath})
    : navigatorKey = GlobalKey<NavigatorState>(),
      _currentPath = initialPath {
    navBloc.stream.listen((navState) {
      final newPath = AppPath.fromNavState(navState);
      if (newPath.routePath != _currentPath.routePath) {
        _currentPath = newPath;
        notifyListeners();
      }
    });

    if (_currentPath.currentScreen == null) {
      _currentPath = AppPath.fromScreen(
        navScreens.firstWhere((s) => s.route == '/placeholder'),
      );
    }
  }

  @override
  AppPath get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    if (_currentPath.currentScreen == null) {
      _currentPath = AppPath.fromScreen(
        navScreens.firstWhere((s) => s.route == '/placeholder'),
      );
    }

    bool isMainTab = navScreens.any(
      (screen) =>
          screen.route == _currentPath.currentScreen?.route && screen.inNavBar,
    );

    Widget resolvedPageContent;

    if (isMainTab) {
      AppPage currentPageEnum = AppPage.placeholder;
      if (_currentPath.currentScreen!.route == '/placeholder') {
        currentPageEnum = AppPage.placeholder;
      } else if (_currentPath.currentScreen!.route == '/navigation') {
        currentPageEnum = AppPage.navigation;
      } else if (_currentPath.currentScreen!.route == '/settings') {
        currentPageEnum = AppPage.settings;
      }

      resolvedPageContent = MainScaffold(
        currentMainPage: currentPageEnum,
        onNavigateToMainPage: (page) {
          navBloc.add(NavTo(page));
        },
        onPushSubPage: (route) {
          navBloc.add(NavPushSubPage(route));
        },
      );
    } else {
      resolvedPageContent = _currentPath.currentScreen!.builder();
    }

    return Navigator(
      key: navigatorKey,
      pages: [
        MainTabPage(
          key: ValueKey(
            isMainTab
                ? 'MainScaffold_${_currentPath.currentScreen!.route}'
                : _currentPath.currentScreen!.route,
          ),
          child: resolvedPageContent,
        ),

        ..._currentPath.subPageStack.map((subRoute) {
          final subPageConfig = navScreenConfigFromRoute(subRoute);
          if (subPageConfig != null) {
            return MainTabPage(
              key: ValueKey(subRoute),
              child: subPageConfig.builder(),
            );
          }

          return MaterialPage(
            child: Center(child: Text('Sub Page: $subRoute - Not Implemented')),
          );
        }),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        if (_currentPath.subPageStack.isNotEmpty) {
          navBloc.add(const NavPopSubPage());
        } else {}
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppPath configuration) async {
    _currentPath = configuration;

    if (configuration.currentScreen != null) {
      AppPage targetPage;
      switch (configuration.currentScreen!.route) {
        case '/placeholder':
          targetPage = AppPage.placeholder;
          break;
        case '/navigation':
          targetPage = AppPage.navigation;
          break;
        case '/settings':
          targetPage = AppPage.settings;
          break;
        default:
          targetPage = AppPage.placeholder;
      }
      navBloc.add(NavTo(targetPage));

      for (var subRoute in configuration.subPageStack) {
        navBloc.add(NavPushSubPage(subRoute));
      }
    }
  }
}

class AppRouteInformationParser extends RouteInformationParser<AppPath> {
  @override
  Future<AppPath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri.toString();
    return AppPath.parse(uri);
  }

  @override
  RouteInformation? restoreRouteInformation(AppPath configuration) {
    return RouteInformation(uri: Uri.parse(configuration.routePath ?? '/'));
  }
}

String routeFromAppPage(AppPage page) {
  final config = navScreens.firstWhere(
    (s) => s.label.toLowerCase() == page.name.toLowerCase() && s.inNavBar,

    orElse: () => navScreens[page.index],
  );
  return config.route;
}

class MainScaffold extends StatefulWidget {
  final AppPage currentMainPage;
  final ValueChanged<AppPage> onNavigateToMainPage;
  final ValueChanged<String> onPushSubPage;

  const MainScaffold({
    super.key,
    required this.currentMainPage,
    required this.onNavigateToMainPage,
    required this.onPushSubPage,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final PageStorageBucket _bucket = PageStorageBucket();
  final Key _placeholderKey = const PageStorageKey<String>('placeholderPage');
  final Key _settingsKey = const PageStorageKey<String>('settingsPage');
  final Key _navigationKey = const PageStorageKey<String>('navigationPage');

  final List<AppPage> _bottomNavOrder = [
    AppPage.placeholder,
    AppPage.navigation,
    AppPage.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final mainPageConfig = navScreenConfigFromRoute(
      routeFromAppPage(widget.currentMainPage),
    );
    bool showBottomNavBar = mainPageConfig?.inNavBar ?? false;

    Widget currentPageWidget;
    switch (widget.currentMainPage) {
      case AppPage.placeholder:
        currentPageWidget = PageStorage(
          bucket: _bucket,
          child: PlaceholderPage(key: _placeholderKey),
        );
        break;
      case AppPage.settings:
        currentPageWidget = PageStorage(
          bucket: _bucket,
          child: SettingsPage(key: _settingsKey),
        );
        break;
      case AppPage.navigation:
        currentPageWidget = PageStorage(
          bucket: _bucket,
          child: NavigationPage(key: _navigationKey),
        );
        break;
    }
    return Scaffold(
      body: currentPageWidget,
      floatingActionButton: PanicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: showBottomNavBar
          ? BottomNavigationBar(
              items: navScreens
                  .where((s) => s.inNavBar)
                  .map(
                    (s) => BottomNavigationBarItem(
                      icon: Icon(s.icon),
                      label: s.label,
                    ),
                  )
                  .toList(),
              currentIndex: _bottomNavOrder.indexOf(widget.currentMainPage),
              onTap: (index) {
                widget.onNavigateToMainPage(_bottomNavOrder[index]);
              },
            )
          : null,
    );
  }
}
