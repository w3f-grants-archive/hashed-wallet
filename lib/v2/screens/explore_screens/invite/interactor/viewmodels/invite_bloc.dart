import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:seeds/v2/blocs/rates/viewmodels/rates_state.dart';
import 'package:seeds/v2/domain-shared/page_state.dart';
import 'package:seeds/v2/domain-shared/shared_use_cases/get_available_balance_use_case.dart';
import 'package:seeds/v2/screens/explore_screens/invite/interactor/mappers/seeds_amount_change_mapper.dart';
import 'package:seeds/v2/screens/explore_screens/invite/interactor/mappers/user_balance_state_mapper.dart';
import 'package:seeds/v2/screens/explore_screens/invite/interactor/viewmodels/bloc.dart';

/// --- BLOC
class InviteBloc extends Bloc<InviteEvent, InviteState> {
  InviteBloc(RatesState rates) : super(InviteState.initial(rates));

  @override
  Stream<InviteState> mapEventToState(InviteEvent event) async* {
    if (event is LoadUserBalance) {
      yield state.copyWith(pageState: PageState.loading);
      Result result = await GetAvailableBalanceUseCase().run();
      yield UserBalanceStateMapper().mapResultToState(state, result, state.ratesState);
    }
    if (event is OnAmountChange) {
      yield SeedsAmountChangeMapper().mapResultToState(state, state.ratesState, event.amountChanged);
    }
    if (event is OnCreateInviteButtonTapped) {
      // next pr
    }
  }
}
