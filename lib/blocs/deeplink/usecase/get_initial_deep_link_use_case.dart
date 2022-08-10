import 'package:async/async.dart';
import 'package:hashed/blocs/deeplink/model/deep_link_data.dart';
import 'package:hashed/datasource/local/account_service.dart';
import 'package:hashed/datasource/local/util/seeds_esr.dart';
import 'package:hashed/domain-shared/shared_use_cases/get_signing_request_use_case.dart';

class GetInitialDeepLinkUseCase {
  GetSigningRequestUseCase getSigningRequestUseCase = GetSigningRequestUseCase();

  Future<DeepLinkData> run(Uri newLink) async {
    final splitUri = newLink.query.split('=');
    final placeHolder = splitUri[0];
    final linkData = splitUri[1];

    final deepLinkPlaceHolder = DeepLinkPlaceHolder.values
        .singleWhere((i) => placeHolder.contains(i.name), orElse: () => DeepLinkPlaceHolder.unknown);

    switch (deepLinkPlaceHolder) {
      case DeepLinkPlaceHolder.guardian:
        final SeedsESR request = SeedsESR(uri: linkData);
        await request.resolve(account: accountService.currentAccount.address);
        final action = request.actions.first;
        final data = Map<String, dynamic>.from(action.data! as Map<dynamic, dynamic>);
        return DeepLinkData(data, deepLinkPlaceHolder);
      case DeepLinkPlaceHolder.invite:
        return DeepLinkData({'Mnemonic': linkData}, deepLinkPlaceHolder);
      case DeepLinkPlaceHolder.invoice:
        final Result esrData = await getSigningRequestUseCase.run(linkData);
        return DeepLinkData({'invoice': esrData}, deepLinkPlaceHolder);
      default:
        return DeepLinkData({}, deepLinkPlaceHolder);
    }
  }
}
