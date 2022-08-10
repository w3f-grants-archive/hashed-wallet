import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hashed/components/flat_button_long.dart';
import 'package:hashed/components/quadstate_clipboard_icon_button.dart';
import 'package:hashed/components/search_result_row.dart';
import 'package:hashed/components/text_form_field_custom.dart';
import 'package:hashed/domain-shared/global_error.dart';
import 'package:hashed/domain-shared/page_state.dart';
import 'package:hashed/domain-shared/ui_constants.dart';
import 'package:hashed/navigation/navigation_service.dart';
import 'package:hashed/screens/authentication/recover/recover_account_search/interactor/viewmodels/recover_account_page_command.dart';
import 'package:hashed/screens/authentication/recover/recover_account_search/interactor/viewmodels/recover_account_search_bloc.dart';
import 'package:hashed/utils/build_context_extension.dart';
import 'package:hashed/utils/debouncer.dart';

class RecoverAccountSearchScreen extends StatefulWidget {
  const RecoverAccountSearchScreen({super.key});

  @override
  _RecoverAccountSearchScreenState createState() => _RecoverAccountSearchScreenState();
}

class _RecoverAccountSearchScreenState extends State<RecoverAccountSearchScreen> {
  final TextEditingController _keyController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _keyController.text = '';
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecoverAccountSearchBloc(),
      child: BlocConsumer<RecoverAccountSearchBloc, RecoverAccountSearchState>(
        listenWhen: (_, current) => current.pageCommand != null,
        listener: (context, state) {
          final pageCommand = state.pageCommand;
          if (pageCommand is NavigateToRecoverAccountFound) {
            NavigationService.of(context).navigateTo(Routes.recoverAccountFound, pageCommand.userAccount);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              minimum: const EdgeInsets.all(horizontalEdgePadding),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormFieldCustom(
                          maxLength: 12,
                          counterText: null,
                          labelText: context.loc.recoverAccountSearchTextFormTitle,
                          controller: _keyController,
                          suffixIcon: QuadStateClipboardIconButton(
                            isChecked: state.isGuardianActive,
                            onClear: () => _keyController.clear(),
                            isLoading: state.pageState == PageState.loading,
                            canClear: _keyController.text.isNotEmpty,
                          ),
                          onChanged: (value) {
                            _debouncer.run(
                                () => BlocProvider.of<RecoverAccountSearchBloc>(context).add(OnUsernameChanged(value)));
                          },
                        ),
                        if (state.accountFound)
                          Container(
                            decoration: BoxDecoration(
                              // color: AppColors.darkGreen2,
                              borderRadius: BorderRadius.circular(defaultCardBorderRadius),
                            ),
                            child: SearchResultRow(
                              member: state.accountInfo!,
                              onTap: () =>
                                  BlocProvider.of<RecoverAccountSearchBloc>(context).add(const OnNextButtonTapped()),
                            ),
                          ),
                        const SizedBox(height: 80),
                        if (state.errorMessage != null)
                          Center(
                            child: Text(
                              state.errorMessage?.localizedDescription(context) ??
                                  GlobalError.unknown.localizedDescription(context),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FlatButtonLong(
                      title: context.loc.recoverAccountSearchButtonTitle,
                      enabled: state.isGuardianActive,
                      onPressed: () =>
                          BlocProvider.of<RecoverAccountSearchBloc>(context).add(const OnNextButtonTapped()),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
