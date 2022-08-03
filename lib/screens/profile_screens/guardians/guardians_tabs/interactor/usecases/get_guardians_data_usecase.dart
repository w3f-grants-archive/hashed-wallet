import 'package:seeds/datasource/local/account_service.dart';
import 'package:seeds/datasource/remote/model/account_guardians_model.dart';
import 'package:seeds/datasource/remote/polkadot_api/polkadot_repository.dart';
import 'package:seeds/utils/result_extension.dart';

class GetGuardiansDataUseCase {
  Future<Result<UserGuardiansModel>> getGuardiansData() {
    return polkadotRepository.getAccountGuardians(accountService.currentAccount.address);
  }
}
