import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seeds/components/custom_dialog.dart';
import 'package:seeds/datasource/local/models/fiat_data_model.dart';
import 'package:seeds/datasource/local/models/token_data_model.dart';
import 'package:seeds/i18n/explore_screens/plant_seeds/plant_seeds.i18n.dart';

class UnplantSeedsSuccessDialog extends StatelessWidget {
  final TokenDataModel unplantedInputAmount;
  final FiatDataModel unplantedInputAmountFiat;

  const UnplantSeedsSuccessDialog(
      {Key? key, required this.unplantedInputAmountFiat, required this.unplantedInputAmount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        return true;
      },
      child: CustomDialog(
        icon: SvgPicture.asset('assets/images/security/success_outlined_icon.svg'),
        singleLargeButtonTitle: 'Close'.i18n,
        onSingleLargeButtonPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                unplantedInputAmount.amountString(),
                style: Theme.of(context).textTheme.headline4,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Text(unplantedInputAmount.symbol, style: Theme.of(context).textTheme.subtitle2),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            unplantedInputAmountFiat.asFormattedString(),
            style: Theme.of(context).textTheme.subtitle2,
          ),
          const SizedBox(height: 20.0),
          Text("Successfully Unplanted!", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headline6),
          const SizedBox(height: 20.0),
          Text(
            'Unplanting Seeds takes 12 weeks in total, with 8.33% of requested amount released each week.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.button,
          ),
        ],
      ),
    );
  }
}