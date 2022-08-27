import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hashed/components/custom_dialog.dart';
import 'package:hashed/datasource/remote/model/generic_transaction_model.dart';
import 'package:hashed/domain-shared/event_bus/event_bus.dart';
import 'package:hashed/domain-shared/event_bus/events.dart';
import 'package:hashed/navigation/navigation_service.dart';
import 'package:hashed/utils/build_context_extension.dart';
import 'package:intl/intl.dart';

class GenericTransactionSuccessDialog extends StatelessWidget {
  final GenericTransactionModel transactionModel;

  const GenericTransactionSuccessDialog(this.transactionModel, {super.key});

  Future<void> show(BuildContext context) {
    return showDialog<void>(context: context, barrierDismissible: false, builder: (_) => this);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: CustomDialog(
          icon: SvgPicture.asset('assets/images/security/success_outlined_icon.svg'),
          singleLargeButtonTitle: context.loc.genericCloseButtonTitle,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("Success", style: Theme.of(context).textTheme.headline4)],
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                Text(context.loc.transferTransactionSuccessDate, style: Theme.of(context).textTheme.subtitle2),
                const SizedBox(width: 16),
                Text(
                  DateFormat('dd MMMM yyyy HH:mm').format(transactionModel.timestamp?.toLocal() ?? DateTime.now()),
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
            Row(
              children: [
                Text("Transaction ID: ", style: Theme.of(context).textTheme.subtitle2),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    transactionModel.transactionId ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  // color: AppColors.lightGreen6,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                            text: transactionModel.transactionId ?? context.loc.transferTransactionSuccessNoID))
                        .then((_) => eventBus.fire(ShowSnackBar(context.loc.transferTransactionSuccessCopiedMessage)));
                  },
                )
              ],
            ),
            Row(
              children: [
                Text(context.loc.transferTransactionSuccessStatus, style: Theme.of(context).textTheme.subtitle2),
                const SizedBox(width: 16),
                Container(
                  decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4, right: 8, left: 8),
                    child: Text(
                      context.loc.transferTransactionSuccessSuccessful,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    context.loc.transferTransactionSuccessCount(transactionModel.transaction.actions.length),
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    NavigationService.of(context)
                        .navigateTo(Routes.transactionActions, transactionModel.transaction.actions);
                  },
                  icon: const Icon(Icons.chevron_right_sharp),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
