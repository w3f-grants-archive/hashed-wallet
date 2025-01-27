import 'package:hashed/datasource/local/models/account.dart';
import 'package:hashed/datasource/local/settings_storage.dart';
import 'package:hashed/datasource/remote/polkadot_api/polkadot_repository.dart';

/// An abstract class for storage services, so we can unit test this class
abstract class AbstractStorage {
  String? get accounts;
  String? get currentAccount;

  void saveAccounts(String jsonFromList);

  Future<String?> getPrivateKeysString();

  Future<void> savePrivateKeys(String privateKeysJsonString);
}

/// An abstract class for key services, so we can unit test this
abstract class KeyRepository {
  Future<String?> publicKeyForPrivateKey(String privateKey);
}

AccountService accountService = AccountService(settingsStorage, polkadotRepository);

class AccountService {
  final AbstractStorage storage;
  final KeyRepository keyRepository;
  List<Account> get accounts => loadAccounts();
  Account get currentAccount => accounts.firstWhere(
        (e) => e.address == storage.currentAccount,
        orElse: () => accounts.isNotEmpty ? accounts[0] : Account.empty,
      );

  AccountService(this.storage, this.keyRepository);

  List<Account> loadAccounts() {
    final accountString = storage.accounts ?? "[]";
    return Account.listFromJson(accountString);
  }

  void saveAccounts(List<Account> accounts) {
    storage.saveAccounts(Account.jsonFromList(accounts));
  }

  Future<Account?> createAccount({required String name, required String privateKey}) async {
    if (privateKey.contains(",")) {
      throw ArgumentError("illegal character in private key: ',': $privateKey");
    }
    Account? result;
    final public = await keyRepository.publicKeyForPrivateKey(privateKey);
    if (public != null) {
      final account = Account(name: name, address: public);
      final accounts = loadAccounts();
      if (!accounts.contains(account)) {
        accounts.add(account);
        saveAccounts(accounts);
      }
      result = account;
      final privateKeys = await getPrivateKeys();
      if (!privateKeys.contains(privateKey)) {
        privateKeys.add(privateKey);
        await savePrivateKeys(privateKeys);
      }
    } else {
      print("Error: Unable to save account");
    }
    return result;
  }

  Future<List<String>> getPrivateKeys() async {
    final privateKeyString = await storage.getPrivateKeysString();
    if (privateKeyString != null) {
      return privateKeyString.split(",");
    } else {
      return [];
    }
  }

  Future<void> savePrivateKeys(List<String> privateKeys) async {
    await storage.savePrivateKeys(privateKeys.join(","));
  }

  Future<String?> getCurrentPrivateKey() async {
    if (currentAccount.isEmpty) {
      return null;
    }
    final currentPublicKey = currentAccount.address;
    final private = await polkadotRepository.privateKeyForPublicKey(currentPublicKey);
    return private;
  }
}
