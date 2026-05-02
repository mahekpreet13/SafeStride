import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// Defines the main pages available in the application.
enum AppPage { placeholder, navigation, settings }

/// Base class for navigation events.
abstract class NavEvent extends Equatable {
  const NavEvent();

  @override
  List<Object?> get props => [];
}

/// Event to navigate to a different main page, clearing subpages.
class NavTo extends NavEvent {
  /// The page to navigate to.
  final AppPage page;
  const NavTo(this.page);

  @override
  List<Object?> get props => [page];
}

/// Event to push a new subpage route onto the stack.
class NavPushSubPage extends NavEvent {
  /// The route identifier of the subpage to push.
  final String route;
  const NavPushSubPage(this.route);

  @override
  List<Object?> get props => [route];
}

/// Event to pop the top subpage route from the stack.
class NavPopSubPage extends NavEvent {
  const NavPopSubPage();
}

/// Event to reset navigation to a specific main page, clearing subpages.
class NavResetToMainPage extends NavEvent {
  /// The main page to reset to.
  final AppPage page;
  const NavResetToMainPage(this.page);

  @override
  List<Object?> get props => [page];
}

/// Represents the current navigation state, including main and subpages.
class NavState extends Equatable {
  /// The current main page.
  final AppPage mainPage;

  /// Stack of subpage route identifiers.
  final List<String> subPageStack;

  const NavState({required this.mainPage, this.subPageStack = const []});

  /// Returns true if there are any subpages on the stack.
  bool get hasSubPages => subPageStack.isNotEmpty;

  /// Returns the current top subpage route, or null if none.
  String? get currentSubPage =>
      subPageStack.isNotEmpty ? subPageStack.last : null;

  /// Returns a new state with updated main page or subpage stack.
  NavState copyWith({AppPage? mainPage, List<String>? subPageStack}) {
    return NavState(
      mainPage: mainPage ?? this.mainPage,
      subPageStack: subPageStack ?? this.subPageStack,
    );
  }

  @override
  List<Object?> get props => [mainPage, subPageStack];
}

/// BLoC that manages navigation between main pages and subpages.
class NavBloc extends Bloc<NavEvent, NavState> {
  /// Creates a NavBloc starting at the placeholder page.
  NavBloc() : super(const NavState(mainPage: AppPage.placeholder)) {
    on<NavTo>(_onNavTo);
    on<NavPushSubPage>(_onNavPushSubPage);
    on<NavPopSubPage>(_onNavPopSubPage);
    on<NavResetToMainPage>(_onNavResetToMainPage);
  }

  /// Handles [NavTo] by setting the main page and clearing subpages.
  void _onNavTo(NavTo event, Emitter<NavState> emit) {
    emit(NavState(mainPage: event.page, subPageStack: const []));
  }

  /// Handles [NavPushSubPage] by adding a route to the subpage stack.
  void _onNavPushSubPage(NavPushSubPage event, Emitter<NavState> emit) {
    final newStack = List<String>.from(state.subPageStack)..add(event.route);
    emit(state.copyWith(subPageStack: newStack));
  }

  /// Handles [NavPopSubPage] by removing the top route if present.
  void _onNavPopSubPage(NavPopSubPage event, Emitter<NavState> emit) {
    if (state.subPageStack.isNotEmpty) {
      final newStack = List<String>.from(state.subPageStack)..removeLast();
      emit(state.copyWith(subPageStack: newStack));
    }
  }

  /// Handles [NavResetToMainPage] by setting the main page and clearing subpages.
  void _onNavResetToMainPage(
    NavResetToMainPage event,
    Emitter<NavState> emit,
  ) {
    emit(NavState(mainPage: event.page, subPageStack: const []));
  }

  /// Convenience method to navigate to a main page.
  void navigateToMainPage(AppPage page) => add(NavTo(page));

  /// Convenience method to push a subpage route.
  void pushSubPage(String route) => add(NavPushSubPage(route));

  /// Convenience method to pop the current subpage.
  void popSubPage() => add(NavPopSubPage());

  /// Convenience method to reset navigation to a main page.
  void resetToMainPage(AppPage page) => add(NavResetToMainPage(page));
}
