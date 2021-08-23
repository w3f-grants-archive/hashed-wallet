import 'package:seeds/components/amount_entry/interactor/mappers/amount_changer_mapper.dart';
import 'package:seeds/components/amount_entry/interactor/mappers/handle_info_row_text.dart';
import 'package:seeds/components/amount_entry/interactor/viewmodels/amount_entry_state.dart';
import 'package:seeds/components/amount_entry/interactor/viewmodels/page_command.dart';
import 'package:seeds/datasource/local/settings_storage.dart';
import 'package:seeds/domain-shared/result_to_state_mapper.dart';
import 'package:seeds/domain-shared/ui_constants.dart';

class CurrencyChangeMapper extends StateMapper {
  AmountEntryState mapResultToState(AmountEntryState currentState) {
    final input = currentState.currentCurrencyInput == CurrencyInput.seeds ? CurrencyInput.fiat : CurrencyInput.seeds;

    return currentState.copyWith(
      currentCurrencyInput: input,
      infoRowText: handleInfoRowText(
        currentCurrencyInput: input,
        fiatToSeeds: currentState.fiatToSeeds,
        seedsToFiat: currentState.seedsToFiat,
      ),
      enteringCurrencyName: handleEnteringCurrencyName(input),
      pageCommand: SendTextInputDataBack(
        handleAmountToSendBack(
          currentCurrencyInput: input,
          textInput: currentState.textInput,
          fiatToSeeds: currentState.fiatToSeeds,
        ),
      ),
    );
  }
}

String handleEnteringCurrencyName(CurrencyInput currentCurrencyInput) {
  switch (currentCurrencyInput) {
    case CurrencyInput.fiat:
      return settingsStorage.selectedFiatCurrency;
    case CurrencyInput.seeds:
      return currencySeedsCode;
  }
}