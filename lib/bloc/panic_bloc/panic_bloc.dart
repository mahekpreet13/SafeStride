import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

part 'panic_events.dart';
part 'panic_states.dart';

/// BLoC that manages panic confirmation and activation flow.
class PanicBloc extends Bloc<PanicEvent, PanicState> {
  /// Timer for auto-canceling the confirmation after timeout.
  Timer? _confirmationTimer;

  /// Timeout duration to wait for user confirmation.
  static const Duration confirmationTimeout = Duration(seconds: 10);

  PanicBloc() : super(PanicInitial()) {
    on<StartPanicConfirmation>(_onStartPanicConfirmation);
    on<CancelPanicConfirmation>(_onCancelPanicConfirmation);
    on<TriggerPanic>(_onTriggerPanic);
    on<ResetPanic>(_onResetPanic);
  }

  /// Begins the confirmation state and starts the timeout.
  void _onStartPanicConfirmation(
    StartPanicConfirmation event,
    Emitter<PanicState> emit,
  ) {
    emit(PanicConfirming());
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(confirmationTimeout, () {
      add(CancelPanicConfirmation());
    });
  }

  /// Cancels the confirmation and returns to the initial state.
  void _onCancelPanicConfirmation(
    CancelPanicConfirmation event,
    Emitter<PanicState> emit,
  ) {
    _confirmationTimer?.cancel();
    emit(PanicInitial());
  }

  /// Activates panic immediately with a timestamp.
  void _onTriggerPanic(
    TriggerPanic event,
    Emitter<PanicState> emit,
  ) {
    _confirmationTimer?.cancel();
    emit(PanicActivated(timestamp: DateTime.now()));
  }

  /// Resets panic back to the initial state.
  void _onResetPanic(
    ResetPanic event,
    Emitter<PanicState> emit,
  ) {
    _confirmationTimer?.cancel();
    emit(PanicInitial());
  }

  @override
  Future<void> close() {
    _confirmationTimer?.cancel();
    return super.close();
  }
}
