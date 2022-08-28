import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hashed/blocs/rates/viewmodels/rates_bloc.dart';
import 'package:hashed/domain-shared/event_bus/event_bus.dart';
import 'package:hashed/domain-shared/event_bus/events.dart';
import 'package:hashed/screens/wallet/components/tokens_cards/tokens_cards.dart';
import 'package:hashed/screens/wallet/components/transactions_list/transactions_list.dart';
import 'package:hashed/screens/wallet/components/wallet_appbar.dart';
import 'package:hashed/screens/wallet/interactor/viewmodels/wallet_bloc.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => WalletBloc()..add(const OnLoadWalletData()),
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          print("error message ${state.errorMessage}");
          return RefreshIndicator(
            onRefresh: () async {
              BlocProvider.of<RatesBloc>(context).add(const OnFetchRates());
              BlocProvider.of<WalletBloc>(context).add(const OnLoadWalletData());
              eventBus.fire(const OnWalletRefreshEventBus());
            },
            child: Scaffold(
              appBar: const WalletAppBar(),
              body: ListView(
                children: [
                  if (state.errorMessage == null)
                    const SizedBox(
                      height: 15,
                    )
                  else
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const TokenCards(),
                  const SizedBox(height: 20),
                  const TransactionsList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
