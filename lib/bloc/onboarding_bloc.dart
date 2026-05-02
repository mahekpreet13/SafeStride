import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base class for onboarding events.
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

/// Event to check if onboarding should be shown.
class CheckOnboardingStatus extends OnboardingEvent {}

/// Event to mark onboarding as completed.
class CompleteOnboarding extends OnboardingEvent {}

/// Event to reset onboarding status (show onboarding again).
class ResetOnboarding extends OnboardingEvent {}

/// State indicating whether onboarding should be shown.
class OnboardingState extends Equatable {
  /// True if onboarding UI should be displayed.
  final bool showOnboarding;
  const OnboardingState({required this.showOnboarding});
  @override
  List<Object?> get props => [showOnboarding];
}

/// BLoC that manages the onboarding flow and persistence.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState(showOnboarding: true)) {
    on<CheckOnboardingStatus>(_onCheckOnboardingStatus);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ResetOnboarding>(_onResetOnboarding);
  }

  /// Loads onboarding completion status from storage and updates state.
  Future<void> _onCheckOnboardingStatus(
    CheckOnboardingStatus event,
    Emitter<OnboardingState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    emit(OnboardingState(showOnboarding: !onboardingComplete));
  }

  /// Marks onboarding as completed in persistent storage.
  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    emit(const OnboardingState(showOnboarding: false));
  }

  /// Resets onboarding status in persistent storage to show onboarding again.
  Future<void> _onResetOnboarding(
    ResetOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', false);
    emit(const OnboardingState(showOnboarding: true));
  }
}
