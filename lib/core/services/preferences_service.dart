import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  bool get isPkrCurrency =>
      _prefs.getString(AppConstants.prefCurrency) == 'PKR';

  Future<void> setCurrency(bool isPkr) async {
    await _prefs.setString(AppConstants.prefCurrency, isPkr ? 'PKR' : 'USD');
  }

  int get simulatedLatency =>
      _prefs.getInt(AppConstants.prefSimulatedLatency) ?? 450;

  Future<void> setSimulatedLatency(int ms) async {
    await _prefs.setInt(AppConstants.prefSimulatedLatency, ms);
  }

  bool get simulateHttp503 =>
      _prefs.getBool(AppConstants.prefSimulateHttp503) ?? false;

  Future<void> setSimulateHttp503(bool simulate) async {
    await _prefs.setBool(AppConstants.prefSimulateHttp503, simulate);
  }
}
