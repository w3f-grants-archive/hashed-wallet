import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hashed/domain-shared/page_command.dart';
import 'package:hashed/domain-shared/page_state.dart';

part 'recover_account_search_event.dart';
part 'recover_account_search_state.dart';

class RecoverAccountSearchBloc extends Bloc<RecoverAccountSearchEvent, RecoverAccountSearchState> {
  RecoverAccountSearchBloc() : super(RecoverAccountSearchState.initial()) {
    on<OnAccountChanged>(_onAccountChanged);
    on<OnNextButtonTapped>(_onNextButtonTapped);
  }

  Future<void> _onAccountChanged(OnAccountChanged event, Emitter<RecoverAccountSearchState> emit) async {
    emit(state.copyWith(account: event.account, isNextEnabled: event.account.isNotEmpty));
  }

  void _onNextButtonTapped(OnNextButtonTapped event, Emitter<RecoverAccountSearchState> emit) {}
}
