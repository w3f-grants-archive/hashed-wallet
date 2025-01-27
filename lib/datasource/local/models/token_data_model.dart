import 'dart:math';

import 'package:hashed/blocs/rates/viewmodels/rates_bloc.dart';
import 'package:hashed/datasource/local/models/amount_data_model.dart';
import 'package:hashed/datasource/local/settings_storage.dart';
import 'package:hashed/datasource/remote/model/token_model.dart';
import 'package:hashed/utils/double_extension.dart';
import 'package:hashed/utils/rate_states_extensions.dart';

class TokenDataModel extends AmountDataModel {
  String? id;
  String? logoUrlAsset;

  TokenDataModel(double amount, {required TokenModel token})
      : super(
          amount: amount,
          symbol: token.symbol,
          precision: token.precision,
        ) {
    id = token.id;
    logoUrlAsset = token.logoUrl;
  }

  TokenDataModel.copy({
    required super.amount,
    required super.symbol,
    required super.precision,
    String? id,
    String? asset,
  }) {
    print("copy with id $id");
    print("copy with asset $asset");
    id = id;
    logoUrlAsset = asset;
  }

  static TokenDataModel? from(double? amount, {TokenModel token = hashedToken}) =>
      amount != null ? TokenDataModel(amount, token: token) : null;

  // ignore: prefer_constructors_over_static_methods
  static TokenDataModel fromSelected(double amount) => TokenDataModel(amount, token: settingsStorage.selectedToken);

  /// display formatted number, no symbol, example "10.00", "10,000,000.00"
  /// format amount by precision, or 4 digits if the precision is > 4 digits.
  String amountString() {
    if (precision >= 4) {
      return fourDigitNumberFormat.format(amount);
    } else if (precision == 2) {
      return twoDigitNumberFormat.format(amount);
    } else {
      return asFixedString();
    }
  }

  int unitAmount() {
    return (amount * pow(10, precision)).toInt();
  }

  double amountFromUnit(String unitAmount) {
    final bigNum = BigInt.parse(unitAmount);
    return bigNum.toDouble() / pow(10, precision);
  }

  // display formatted number and symbol, example "10.00 SEEDS", "1,234.56 SEEDS"
  String amountStringWithSymbol() {
    return "${amountString()} $symbol";
  }

  TokenDataModel copyWith(double amount) {
    return TokenDataModel.copy(amount: amount, asset: logoUrlAsset, symbol: symbol, id: id, precision: precision);
  }
}

extension FormatterTokenModel on TokenDataModel {
// Convenience method: directly get a fiat converted string from a token model
// tokenModel.fiatString(...) => "12.34 EUR"
  String? fiatString(RatesState rateState) {
    return rateState.tokenToFiat(this, settingsStorage.selectedFiatCurrency)?.asFormattedString();
  }
}
