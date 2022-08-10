import 'dart:async';

import 'package:hashed/polkadot/sdk_0.4.8/lib/api/api.dart';
import 'package:hashed/polkadot/sdk_0.4.8/lib/api/types/balanceData.dart';
import 'package:hashed/polkadot/sdk_0.4.8/lib/plugin/store/balances.dart';
import 'package:hashed/polkadot/sdk_0.4.8/lib/service/assets.dart';

class ApiAssets {
  ApiAssets(this.apiRoot, this.service);

  final PolkawalletApi apiRoot;
  final ServiceAssets service;

  Future<List<TokenBalanceData>> getAssetsAll() async {
    final List res = await (service.getAssetsAll() as FutureOr<List<dynamic>>);
    return res
        .map((e) => TokenBalanceData(
              id: e['id'].toString(),
              name: e['symbol'],
              fullName: e['name'],
              symbol: e['symbol'],
              decimals: int.parse(e['decimals']),
            ))
        .toList();
  }

  Future<List<AssetsBalanceData>> queryAssetsBalances(List<String> ids, String address) async {
    final res = await service.queryAssetsBalances(ids, address);

    return res
        .asMap()
        .map((k, v) {
          final e = v ?? {};
          e['id'] = ids[k];
          return MapEntry(k, v != null ? AssetsBalanceData.fromJson(e) : AssetsBalanceData());
        })
        .values
        .toList();
  }
}
