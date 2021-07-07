import 'package:seeds/v2/datasource/remote/model/profile_model.dart';
import 'package:seeds/v2/datasource/remote/model/vote_model.dart';
import 'package:seeds/v2/domain-shared/page_state.dart';
import 'package:seeds/v2/domain-shared/result_to_state_mapper.dart';
import '../viewmodels/proposal_details_state.dart';

class ProposalDataStateMapper extends StateMapper {
  ProposalDetailsState mapResultsToState(ProposalDetailsState currentState, List<Result> results) {
    if (areAllResultsError(results)) {
      return currentState.copyWith(pageState: PageState.failure, errorMessage: 'Error Loading Page');
    } else {
      results.retainWhere((Result i) => i.isValue);
      var values = results.map((Result i) => i.asValue!.value).toList();

      ProfileModel? profileModel = values.firstWhere((i) => i is ProfileModel, orElse: () => null);
      VoteModel? voteModel = values.firstWhere((i) => i is VoteModel, orElse: () => null);

      return currentState.copyWith(
        pageState: PageState.success,
        isAlreadyPrecasted: voteModel!.amount != 0,
        creator: profileModel,
      );
    }
  }
}