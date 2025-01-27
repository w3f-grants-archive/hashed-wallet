import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hashed/components/flat_button_long.dart';
import 'package:hashed/components/search_user/interactor/viewmodels/search_user_bloc.dart';
import 'package:hashed/components/text_form_field_custom.dart';
import 'package:hashed/datasource/local/models/account.dart';
import 'package:hashed/domain-shared/page_state.dart';
import 'package:hashed/domain-shared/ui_constants.dart';

class SearchUser extends StatelessWidget {
  final ValueSetter<Account> onUserSelected;
  final clipboardTextController = TextEditingController();

  SearchUser({
    super.key,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchUserBloc>(
      create: (_) => SearchUserBloc(),
      child: BlocBuilder<SearchUserBloc, SearchUserState>(
        builder: (context, state) {
          return Column(children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 4, left: horizontalEdgePadding, right: horizontalEdgePadding),
                child: TextFormFieldCustom(
                  controller: clipboardTextController,
                  maxLines: 2,
                  autofocus: true,
                  labelText: "Send to",
                  hintText: "Address",
                  errorText: state.errorMessage,
                  errorMaxLines: 10,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      final clipboardData = await Clipboard.getData('text/plain');
                      final clipboardText = clipboardData?.text ?? '';
                      clipboardTextController.text = clipboardText;
                      // ignore: use_build_context_synchronously
                      BlocProvider.of<SearchUserBloc>(context).add(OnSearchChange(searchQuery: clipboardText));
                    },
                  ),
                  onChanged: (value) {
                    BlocProvider.of<SearchUserBloc>(context).add(OnSearchChange(searchQuery: value));
                  },
                )),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(state.hasName ? state.name : ""),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: horizontalEdgePadding),
                child: FlatButtonLong(
                  title: 'Next',
                  isLoading: state.pageState == PageState.loading,
                  enabled: state.account != null,
                  onPressed: () => onUserSelected(state.account!),
                )),
          ]);
        },
      ),
    );
  }
}
