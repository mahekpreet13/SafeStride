part of 'panic_bloc.dart';

abstract class PanicEvent {}

class TriggerPanic extends PanicEvent {
  final String? reason;

  TriggerPanic({this.reason});
}

class ResetPanic extends PanicEvent {}

class StartPanicConfirmation extends PanicEvent {}

class CancelPanicConfirmation extends PanicEvent {}
