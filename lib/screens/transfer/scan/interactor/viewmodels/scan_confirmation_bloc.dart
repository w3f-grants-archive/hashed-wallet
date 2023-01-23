import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hashed/datasource/local/models/scan_qr_code_result_data.dart';
import 'package:hashed/datasource/local/models/substrate_signing_request_model.dart';
import 'package:hashed/datasource/local/signing_request_repository.dart';
import 'package:hashed/domain-shared/page_command.dart';
import 'package:hashed/domain-shared/page_state.dart';
import 'package:hashed/domain-shared/result_to_state_mapper.dart';
import 'package:hashed/screens/transfer/scan/interactor/viewmodels/scan_confirmation_commands.dart';
import 'package:hashed/screens/transfer/scan/scan_confirmation_action.dart';

part 'scan_confirmation_events.dart';
part 'scan_confirmation_state.dart';

class ScanConfirmationBloc extends Bloc<ScanConfirmationEvent, ScanConfirmationState> {
  ScanConfirmationBloc() : super(ScanConfirmationState.initial()) {
    on<Initial>(_initial);
    on<OnSendTapped>(_onSendTapped);
    on<OnDoneTapped>(_onDoneTapped);
    on<ClearPageCommand>((_, emit) => emit(state.copyWith()));
  }

  Future<void> _initial(Initial event, Emitter<ScanConfirmationState> emit) async {
    emit(state.copyWith(pageState: PageState.loading));

    // TODO(NIK): here is where you make the calls to fetch Initial data. Inside a use case
    final Result<List<ScanConfirmationActionData>> result = event.signingRequest == null
        ? Result.error("No signing request")
        : Result.value(event.signingRequest!.signingRequestModel.toSendConfirmationData());
    if (result.isValue) {
      emit(state.copyWith(
        actions: result.asValue!.value,
        signingRequest: event.signingRequest!.signingRequestModel,
        pageState: PageState.success,
        // filtered: result.asValue!.value,
      ));
    } else {
      emit(state.copyWith(pageState: PageState.failure));
    }
  }

  FutureOr<void> _onDoneTapped(OnDoneTapped event, Emitter<ScanConfirmationState> emit) {
    emit(state.copyWith(pageCommand: NavigateHome()));
  }

  FutureOr<void> _onSendTapped(OnSendTapped event, Emitter<ScanConfirmationState> emit) async {
    emit(state.copyWith(actionButtonLoading: true));

    final result = await SigningRequestRepository().signAndSendSigningRequest(state.signingRequest!);

    if (result.isValue) {
      emit(state.copyWith(
        actionButtonLoading: false,
        pageCommand: ShowTransactionSuccess(),
      ));
    } else {
      emit(state.copyWith(
        actionButtonLoading: false,
        transactionSendError: 'Error',
      ));
    }
  }
}
