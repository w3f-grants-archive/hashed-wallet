import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:hashed/datasource/local/account_service.dart';
import 'package:hashed/datasource/local/flutter_js/polkawallet_init.dart';
import 'package:hashed/datasource/remote/model/guardians_config_model.dart';
import 'package:hashed/datasource/remote/model/token_model.dart';
import 'package:hashed/datasource/remote/polkadot_api/recovery_repository.dart';
import 'package:hashed/utils/result_extension.dart';

PolkadotRepository polkadotRepository = PolkadotRepository();

class PolkadotRepositoryState {
  bool isInitialized = false;
  bool isConnected = false;
}

class PolkadotRepository extends KeyRepository {
  late PolkawalletInit? _polkawalletInit;

  bool get isInitialized => state.isInitialized;
  bool get isConnected => state.isConnected;

  PolkadotRepositoryState state = PolkadotRepositoryState();

  void handleConnectState(bool isConnected) {
    print("PolkadotRepository connection state ${isConnected ? 'Connected' : 'Disconnected'}");
    state.isConnected = isConnected;
  }

  bool initialized = false;
  Future<void> initService() async {
    try {
      if (initialized) {
        print("ignore second init");
        //print(StackTrace.current);
        // Note:
        // Currently some code - like get balance - is checking for init, and when not initialized,
        // it calls initialize. This gets called during initialization a few times, so this code is still
        // needed. Check init should probably just stall while initialize is happening?
        return;
      }
      initialized = true;
      print("PolkadotRepository init");

      _polkawalletInit = PolkawalletInit(handleConnectState);

      await _polkawalletInit!.init();

      state.isInitialized = true;

      await _cryptoWaitReady();
      await _initKeys();
    } catch (err) {
      print("Error: $err");
      rethrow;
    }
  }

  Future<bool> startService() async {
    try {
      print("PolkadotRepository start");
      await _polkawalletInit!.init();
      await _polkawalletInit!.connect();
      state.isConnected = true;

      return true;
    } catch (err) {
      print("Error: $err");
      state.isConnected = false;

      rethrow;
    }
  }

  Future<bool> stopService() async {
    await _polkawalletInit?.stop();
    _polkawalletInit = null;
    state.isInitialized = false;

    return true;
  }

  Future<void> _checkInitialized() async {
    if (state.isInitialized == false) {
      await initService();
    }
  }

  Future<void> _checkConnected() async {
    await _checkInitialized();
    if (state.isConnected == false) {
      await startService();
    }
  }

  /// This is a little hack
  /// Before any crypto call, we must call cryptoWaitReady in the polkadot JS code
  /// However the wrapper does not expose that method
  /// However, it exposes another method that calls cryptoWaitready, which is initKeys()
  /// So we simply call initKeys() with empty parameters - it calls crypto wait ready and doesn't
  /// do anything else.
  /// [POLKA] Fix the JS API to export cryptoWaitReady - when we have time
  Future<void> _cryptoWaitReady() async {
    // async function initKeys(accounts: KeyringPair$Json[], ss58Formats: number[]) {
    final res = await _polkawalletInit?.webView?.evalJavascript('keyring.initKeys([], [])');
    print("wait ready res: $res");
  }

  Future<void> _initKeys() async {
    final keys = await accountService.getPrivateKeys();

    for (final mnemonic in keys) {
      print("PJS: import key $mnemonic");
      await importKey(mnemonic);
    }
  }

  Future<String> createKey() async {
    await _checkInitialized();

    final res = await _polkawalletInit?.webView?.evalJavascript('keyring.gen(null, 42, "sr25519", "")');
    //print("create res: $res");
    final String mnemonic = res["mnemonic"];
    //print("mnemonic $mnemonic");
    return mnemonic;
  }

  // api.query.system.account(steve.address)
  Future<double> getBalance(String address) async {
    try {
      print("get balance for $address");
      await _checkInitialized();
      await _checkConnected();

      // Debug code, do not check in - checking account with known address
      // final knownAddress = "5GwwAKFomhgd4AHXZLUBVK3B792DvgQUnoHTtQNkwmt5h17k";
      // final resJson = await _polkawalletInit?.webView?.evalJavascript('api.query.system.account("$knownAddress")');

      final resJson = await _polkawalletInit?.webView?.evalJavascript('api.query.system.account("$address")');

      // print("result STRING $resJson");
      // flutter: result STRING: {nonce: 0, consumers: 0, providers: 0, sufficients: 0, data: {free: 0, reserved: 0, miscFrozen: 0, feeFrozen: 0}}

      /// this value is an int if it's small enough.
      /// Not sure what will happen if the number is too big but one would assume it
      /// would then get sent as a string. So we always convert it to a string.
      final free = resJson["data"]["free"];
      final freeString = "$free";
      final bigNum = BigInt.parse(freeString);
      final double result = bigNum.toDouble() / pow(10, hashedToken.precision);

      //print("free type: ${free.runtimeType} ==> $bigNum ==> $result");

      return result;
    } catch (error) {
      print("Error getting balance $error");
      print(error);
      rethrow;
    }
  }

  Future<dynamic> testImport() async {
    await _checkInitialized();
    // known mnemonic, well, now it is - don't use it for funds
    final mnemonicFromPolkaTutorial = 'sample split bamboo west visual approve brain fox arch impact relief smile';
    final res = await importKey(mnemonicFromPolkaTutorial);
    return res;
  }

  Future<String> importKey(String mnemonic) async {
    await _checkInitialized();

    /// Notes
    /// 1 - Variables declared raw are global variables
    /// 2 - Here we use last_pair to store the last added keypair so we can return it
    /// 3 - We have to stringify the result since we otherwise get an unsupported type exception and nothing
    /// is returned.
    /// 4 - without debug output could use the method with wrapPromise = true and would probably get the result
    final code = '''
      console.log(keyring.pKeyring, 'pkeyring before');
      console.log(keyring.pKeyring.pairs.length, 'pairs before');

      // generic substrate format
      keyring.pKeyring.setSS58Format(42);

      // create & add the pair to the keyring with the type and some additional
      // metadata specified
      last_pair = keyring.pKeyring.addFromUri("$mnemonic", { name: 'first pair' }, 'sr25519');

      // the pair has been added to our keyring
      console.log(keyring.pKeyring.pairs.length, 'pairs available');


      // log the name & address (the latter encoded with the ss58Format)
      // console.log(last_pair.meta.name, ' ==> ', JSON.stringify(last_pair, null, 2));

      // return result
      JSON.stringify(last_pair);
    ''';
    try {
      final res = await _polkawalletInit?.webView?.evalJavascript(code, wrapPromise: false);
      print("result importKey $res");
      return res["address"];
    } catch (err) {
      print("error $err");
      rethrow;
    }
  }

  @override
  Future<String?> publicKeyForPrivateKey(String privateKey) async {
    await _checkInitialized();

    /// 1 - set format
    /// 2 - call addFromUri, which returns a keypair object
    /// 3 - encode the keypair in JSON so we return a string
    /// Flutter code can then JSON decode the string
    final code = '''
      keyring.pKeyring.setSS58Format(42);
      last_pair = keyring.pKeyring.addFromUri("$privateKey", { name: '' }, 'sr25519');
      JSON.stringify(last_pair);
    ''';
    try {
      final res = await _polkawalletInit?.webView?.evalJavascript(code, wrapPromise: false);
      final json = jsonDecode(res);
      return json["address"];
    } catch (err) {
      print("error $err");
      rethrow;
    }
  }

  Future<String?> privateKeyForPublicKey(String publicKey) async {
    await _checkInitialized();

    final keys = await accountService.getPrivateKeys();

    for (final key in keys) {
      final pk = await publicKeyForPrivateKey(key);
      if (pk == publicKey) {
        return key;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> getKeyPair(String address) async {
    final code = 'JSON.stringify(keyring.pKeyring.getPair("$address"))';
    final res = await _polkawalletInit?.webView?.evalJavascript(code, wrapPromise: false);
    final keyPair = jsonDecode(res);
    return keyPair;
  }

  /// Note: The APIs sometimes take a public key instead of an address - this converts
  /// one into the other. Public key is in map format but the function u8aToHex converts that
  /// correctly to hex.
  Future<Map<String, dynamic>> getPublicKey(String address) async {
    final keyPair = await getKeyPair(address);
    final pubkey = keyPair["publicKey"];
    return pubkey;
  }

  /// Activates your guardians - Min 2 for now. (UI enforced)
  Future<Result> createRecovery(GuardiansConfigModel guardians) async {
    print("create recovery: ${guardians.toJson()}");
    try {
      final res = await RecoveryRepositry(_polkawalletInit!.webView!).createRecovery(
        address: accountService.currentAccount.address,
        guardians: guardians.guardianAddresses,
        threshold: guardians.threshold,
        delayPeriod: guardians.delayPeriod,
      );
      return Result.value(res);
    } catch (err) {
      return Result.error(err);
    }
  }

  Future<Result> getActiveRecovery() async {
    throw UnimplementedError();
  }

  Future<Result<GuardiansConfigModel>> getRecoveryConfig(String address) async {
    print("get guardians for $address");

    // TODO(n13): Create a mapper for polkadot API results - similar to httpmapper
    // then add model mappers for all the different possible responses.
    // But, make it work first -
    try {
      final code = 'api.query.recovery.recoverable("$address")';
      final res = await _polkawalletInit?.webView?.evalJavascript(code);
      print("getRecoveryConfig res: $res");
      GuardiansConfigModel guardiansModel;
      if (res != null) {
        guardiansModel = GuardiansConfigModel.fromJson(res);
      } else {
        return Result.value(GuardiansConfigModel.empty());
      }
      return Result.value(guardiansModel);
    } catch (err) {
      print('getRecoveryConfig error: $err');
      return Result.error(err);
    }
  }

  Future<Result<dynamic>> initiateRecovery(String address) async {
    print("initiate recovery for $address");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }

  /// return recoveries that are currently in process for the address in question
  /// Params: Address to be recovered
  Future<Result<List<dynamic>>> getActiveRecoveries(String address) async {
    print("get active recovery for $address");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value(["Ok"]));
  }

  Future<Result<dynamic>> vouch({required String lostAccountAddress, required String newAccountAddress}) async {
    print("vouch for recovering $lostAccountAddress on behalf of $newAccountAddress");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }

  /// Claim recovery
  /// after that account can make calls with asRecovered
  ///
  /// Also after that we can close, remove and cancel.
  ///
  /// Close recovery - claims some fees back
  /// Remove recovery - claims some fees back
  /// Cancel recovered - removes ability to call asRecovered
  ///
  Future<Result<dynamic>> claimRecovery(String lostAccountAddress) async {
    print("claim recovered account $lostAccountAddress");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }

  Future<Result<dynamic>> asRecovered(String recoveredAccount, dynamic polkadotCall) async {
    print("make a call on behalf of $recoveredAccount");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }

  /// This transfers all funds from recoveredAccount to the currently active account
  /// It's a shortcut to a transfer through asRecovered.
  Future<Result<dynamic>> recoverFundsFor(String recoveredAccount) async {
    print("transfer funds from $recoveredAccount to currently active account");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }

  ///
  /// As the controller of a recoverable account, close an active recovery process for your account.
  /// Payment: By calling this function, the recoverable account will receive the recovery deposit RecoveryDeposit placed by the rescuer.
  /// The dispatch origin for this call must be Signed and must be a recoverable account with an active recovery process for it.
  /// Parameters:
  /// rescuer: The account trying to rescue this recoverable account.
  ///
  /// Note: this can be used to end a malicious recovery attempt.
  ///
  Future<Result<dynamic>> closeRecovery(String rescuerAccount) async {
    final account = accountService.currentAccount.address;
    print("closing recovery on $account by $rescuerAccount");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }

  /// Removes user's guardians. User must Start from scratch.
  /// Recovers fees.
  Future<Result> removeRecovery() async {
    try {
      final res = await RecoveryRepositry(_polkawalletInit!.webView!)
          .removeRecovery(address: accountService.currentAccount.address);
      return Result.value(res);
    } on Exception catch (err) {
      return Result.error(err);
    }
  }

  /// I am guessing this removes the "as_recovered" recovery entry from the pallet, freeing up some storage
  /// and recovering some fees.
  Future<Result<dynamic>> cancelRecovered(String recoveredAccount) async {
    print("cancel recovery for $recoveredAccount");
    return Future.delayed(const Duration(milliseconds: 500), () => Result.value("Ok"));
  }
}
