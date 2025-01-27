import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hashed/datasource/local/account_service.dart';
import 'package:hashed/datasource/local/models/auth_data_model.dart';
import 'package:hashed/datasource/remote/model/token_model.dart';
import 'package:hashed/domain-shared/app_constants.dart';
import 'package:hashed/domain-shared/ui_constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys
const String _kPasscode = 'passcode';
const String _kPasscodeActive = 'passcode_active';
const String _kBiometricActive = 'biometric_active';
const String _kPrivateKeyBackedUp = 'private_key_backed_up';
const String _kSelectedFiatCurrency = 'selected_fiat_currency';
const String _kSelectedToken = 'selected_token';
const String _kInRecoveryMode = 'in_recovery_mode';
const String _kRecoveryLink = 'recovery_link';
const String _kIsCitizen = 'is_citizen';
const String _kIsFirstRun = 'is_first_run';
const String _kDateSinceRateAppPrompted = 'date_since_rate_app_prompted';

const String _kAccounts = "accounts";
const String _kCurrentAccount = "current_account";
const String _kPrivateKeys = "private_keys";

const String _kActiveRecoveryAccount = "active_recovery_account";

const String _kCurrentNetwork = "current_network";

class _SettingsStorage implements AbstractStorage {
  late SharedPreferences _preferences;
  late FlutterSecureStorage _secureStorage;

  // These nullable fields below are initialized from
  // secure storage, to avoid call a Future often
  String? _passcode;

  // TODO(n13): Passcode is temporarily disabled.
  // ignore: unused_field, use_late_for_private_fields_and_variables
  bool? _passcodeActive;
  // ignore: unused_field, use_late_for_private_fields_and_variables
  bool? _biometricActive;

  factory _SettingsStorage() => _instance;

  _SettingsStorage._();

  static final _SettingsStorage _instance = _SettingsStorage._();

  String? get passcode => _passcode;

  // TODO(n13): Passcode is disabled for now.
  bool get passcodeActive => false; // _passcodeActive ?? false;

  // TODO(n13): Passcode is disabled for now.
  bool? get biometricActive => false; // _biometricActive;

  bool get privateKeyBackedUp => _preferences.getBool(_kPrivateKeyBackedUp) ?? false; // <-- No used, need re-add PR 182

  String get selectedFiatCurrency => _preferences.getString(_kSelectedFiatCurrency) ?? getPlatformCurrency();

  TokenModel get selectedToken => TokenModel.fromId(_preferences.getString(_kSelectedToken) ?? hashedToken.id);

  bool get inRecoveryMode => _preferences.getBool(_kInRecoveryMode) ?? false;

  String get recoveryLink => _preferences.getString(_kRecoveryLink) ?? '';

  bool get isCitizen => _preferences.getBool(_kIsCitizen) ?? false;

  int? get dateSinceRateAppPrompted => _preferences.getInt(_kDateSinceRateAppPrompted);

  String get currentNetwork => _preferences.getString(_kCurrentNetwork) ?? hashedNetworkId;
  set currentNetwork(String value) => _preferences.setString(_kCurrentNetwork, value);

  set inRecoveryMode(bool value) => _preferences.setBool(_kInRecoveryMode, value);

  set recoveryLink(String? value) =>
      value == null ? _preferences.remove(_kRecoveryLink) : _preferences.setString(_kRecoveryLink, value);

  set passcode(String? value) {
    _secureStorage.write(key: _kPasscode, value: value);
    _passcode = value;
  }

  set passcodeActive(bool? value) {
    _secureStorage.write(key: _kPasscodeActive, value: value.toString());
    if (value != null) {
      _passcodeActive = value;
    }
  }

  set biometricActive(bool? value) {
    _secureStorage.write(key: _kBiometricActive, value: value.toString());
    if (value != null) {
      _biometricActive = value;
    }
  }

  set privateKeyBackedUp(bool? value) {
    if (value != null) {
      _preferences.setBool(_kPrivateKeyBackedUp, value);
    }
  }

  set selectedFiatCurrency(String? value) {
    if (value != null) {
      _preferences.setString(_kSelectedFiatCurrency, value);
    }
  }

  set selectedToken(TokenModel token) {
    _preferences.setString(_kSelectedToken, token.id);
  }

  set isCitizen(bool? value) {
    if (value != null) {
      _preferences.setBool(_kIsCitizen, value);
    }
  }

  set dateSinceRateAppPrompted(int? value) {
    if (value != null) {
      _preferences.setInt(_kDateSinceRateAppPrompted, value);
    }
  }

  /// Store the fact that there is an active recovery in process for a specific account
  /// We can change this to a list later on
  String? get activeRecoveryAccount => _preferences.getString(_kActiveRecoveryAccount);

  set activeRecoveryAccount(String? value) {
    if (value != null) {
      _preferences.setString(_kActiveRecoveryAccount, value);
    } else {
      _preferences.remove(_kActiveRecoveryAccount);
    }
  }

  Future<void> initialise() async {
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();

    // on iOS secure storage items are not deleted on app uninstall - must be deleted manually
    // [POLKA] revisit this
    // if (accountName.isEmpty && (_preferences.getBool(_kIsFirstRun) ?? true)) {
    //   await _secureStorage.deleteAll();
    // }
    await _preferences.setBool(_kIsFirstRun, false);

    await _secureStorage.readAll().then((values) {
      _passcode = values[_kPasscode];
      _passcode ??= _migrateFromPrefs(_kPasscode); // <-- passcode is not in pref

      if (values.containsKey(_kPasscodeActive)) {
        _passcodeActive = values[_kPasscodeActive] == 'true';
      } else {
        _passcodeActive = true;
      }

      if (values.containsKey(_kBiometricActive)) {
        _biometricActive = values[_kBiometricActive] == 'true';
      } else {
        _biometricActive = false;
      }
    });
  }

  // Used to migrate old settings versions
  String? _migrateFromPrefs(String key) {
    final String? value = _preferences.get(key) as String?;
    if (value != null) {
      _secureStorage.write(key: key, value: value);
      _preferences.remove(key);
      print('Converted $key to secure storage');
    }
    return value;
  }

  Future<void> startRecoveryProcess({
    required String accountName,
    required String recoveryLink,
  }) async {
    // [POLKA] fix this
    throw UnimplementedError();
    // inRecoveryMode = true;
    // _accountName = accountName;
    // this.recoveryLink = recoveryLink;
    // await accountService.createAccount(name: accountName, privateKey: authData.wordsString);
  }

  void finishRecoveryProcess() {
    privateKeyBackedUp = false;
    inRecoveryMode = false;
    recoveryLink = null;
  }

  /// Notice this function it's also called on `Import (login screen)`
  /// and `Singup`. To cancel any recover process previously started
  Future<void> cancelRecoveryProcess() async {
    await _preferences.clear();
    await _secureStorage.deleteAll();
  }

  void enablePasscode(String? passcode) {
    this.passcode = passcode;
    passcodeActive = true;
  }

  void disablePasscode() {
    passcode = null;
    passcodeActive = false;
    biometricActive = false;
  }

  @override
  void saveAccounts(String accountsListJsonString) {
    _preferences.setString(_kAccounts, accountsListJsonString);
  }

  @override
  String? get accounts => _preferences.getString(_kAccounts);
  @override
  String? get currentAccount => _preferences.getString(_kCurrentAccount);
  set currentAccount(String? value) =>
      value == null ? _preferences.remove(_kCurrentAccount) : _preferences.setString(_kCurrentAccount, value);

  @override
  Future<String?> getPrivateKeysString() async {
    return _secureStorage.read(key: _kPrivateKeys);
  }

  @override
  Future<void> savePrivateKeys(String privateKeysJsonString) async {
    await _secureStorage.write(key: _kPrivateKeys, value: privateKeysJsonString);
  }

  /// Update current accout name, private key and remove some pref
  Future<void> switchAccount(String accountName, AuthDataModel authData) async {
    throw UnimplementedError("This is part of AccountService");
    // privateKeyBackedUp = false;
    // _accountName = accountName;
    // await Future.wait([
    //   // _preferences.remove(_kSelectedFiatCurrency),
    //   // _preferences.remove(_kSelectedToken),
    //   // _preferences.remove(_kIsCitizen),
    //   // _preferences.remove(_kIsVisitor),
    // ]);
  }

  // ignore: use_setters_to_change_properties
  void savePrivateKeyBackedUp(bool value) => privateKeyBackedUp = value;

  // ignore: use_setters_to_change_properties
  void saveSelectedFiatCurrency(String value) => selectedFiatCurrency = value;

  // ignore: use_setters_to_change_properties
  void saveDateSinceRateAppPrompted(int value) => dateSinceRateAppPrompted = value;

  Future<void> removeAccount() async {
    await _preferences.clear();
    await _secureStorage.deleteAll();
    _passcode = null;
    _passcodeActive = true;
    _biometricActive = false;
  }

  String getPlatformCurrency() {
    final format = NumberFormat.simpleCurrency(locale: Platform.localeName);
    return format.currencyName ?? currencyDefaultCode;
  }
}

/// Singleton
_SettingsStorage settingsStorage = _SettingsStorage();
