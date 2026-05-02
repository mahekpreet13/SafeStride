part of 'panic_bloc.dart';

abstract class PanicState {}

class PanicInitial extends PanicState {}

class PanicConfirming extends PanicState {}

class PanicActivated extends PanicState {
  final DateTime timestamp;

  PanicActivated({DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
