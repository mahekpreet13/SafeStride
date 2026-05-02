import 'package:equatable/equatable.dart';

enum VruCategory { blind, visuallyImpaired }

class SettingsState extends Equatable {
  final VruCategory? vruCategory;
  final String? emergencyContact;
  final String? apiData;

  const SettingsState({this.vruCategory, this.emergencyContact, this.apiData});

  SettingsState copyWith({
    VruCategory? vruCategory,
    String? emergencyContact,
    String? apiData,
  }) {
    return SettingsState(
      vruCategory: vruCategory ?? this.vruCategory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      apiData: apiData ?? this.apiData,
    );
  }

  @override
  List<Object?> get props => [vruCategory, emergencyContact, apiData];
}
