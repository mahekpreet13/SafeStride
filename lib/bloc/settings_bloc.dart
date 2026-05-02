import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

/// Base class for all settings-related events.
abstract class SettingsEvent {}

/// Event to set the selected VRU (Vulnerable Road User) category.
class SetVruCategory extends SettingsEvent {
  /// The VRU category to set.
  final VruCategory category;
  SetVruCategory(this.category);
}

/// Event to set the emergency contact string.
class SetEmergencyContact extends SettingsEvent {
  /// The emergency contact value.
  final String contact;
  SetEmergencyContact(this.contact);
}

/// Event to set arbitrary API data (such as tokens or config).
class SetApiData extends SettingsEvent {
  /// The API data value.
  final String data;
  SetApiData(this.data);
}

/// Event to load all settings from persistent storage.
class LoadSettings extends SettingsEvent {}

/// Event to reset onboarding status for the user.
class ResetOnboarding extends SettingsEvent {}

/// BLoC that handles user and app settings, with persistence.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<SetVruCategory>(_onSetVruCategory);
    on<SetEmergencyContact>(_onSetEmergencyContact);
    on<SetApiData>(_onSetApiData);
    on<ResetOnboarding>(_onResetOnboarding);
    add(LoadSettings());
  }

  /// Loads settings from [SharedPreferences] and updates state.
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final vruIndex = prefs.getInt('vruCategory');
    final contact = prefs.getString('emergencyContact');
    final apiData = prefs.getString('apiData');
    emit(
      state.copyWith(
        vruCategory: vruIndex != null ? VruCategory.values[vruIndex] : null,
        emergencyContact: contact,
        apiData: apiData,
      ),
    );
  }

  /// Persists the selected VRU category and updates state.
  Future<void> _onSetVruCategory(
    SetVruCategory event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vruCategory', event.category.index);
    emit(state.copyWith(vruCategory: event.category));
  }

  /// Persists the emergency contact and updates state.
  Future<void> _onSetEmergencyContact(
    SetEmergencyContact event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergencyContact', event.contact);
    emit(state.copyWith(emergencyContact: event.contact));
  }

  /// Persists the API data and updates state.
  Future<void> _onSetApiData(
    SetApiData event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiData', event.data);
    emit(state.copyWith(apiData: event.data));
  }

  /// Resets onboarding status in persistent storage.
  Future<void> _onResetOnboarding(
    ResetOnboarding event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', false);
  }
}
