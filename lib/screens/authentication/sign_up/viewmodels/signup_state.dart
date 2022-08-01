part of 'signup_bloc.dart';

enum SignupScreens { displayName, accountName }

class SignupState extends Equatable {
  final PageState pageState;
  final PageCommand? pageCommand;
  final SignUpError? error;
  final SignupScreens signupScreens;
  final InviteModel? inviteModel;
  final String? inviteMnemonic;
  final bool fromDeepLink;
  final String? accountName;
  final String? displayName;

  const SignupState({
    required this.pageState,
    this.pageCommand,
    this.error,
    required this.signupScreens,
    this.inviteModel,
    this.inviteMnemonic,
    required this.fromDeepLink,
    this.accountName,
    this.displayName,
  });

  @override
  List<Object?> get props => [
        pageState,
        pageCommand,
        error,
        signupScreens,
        inviteModel,
        inviteMnemonic,
        fromDeepLink,
        accountName,
        displayName,
      ];

  bool get isUsernameValid => !accountName.isNullOrEmpty && pageState == PageState.success;

  bool get isNextButtonActive => isUsernameValid;

  SignupState copyWith({
    PageState? pageState,
    PageCommand? pageCommand,
    SignUpError? error,
    SignupScreens? signupScreens,
    InviteModel? inviteModel,
    String? inviteMnemonic,
    bool? fromDeepLink,
    String? accountName,
    String? displayName,
  }) =>
      SignupState(
        pageState: pageState ?? this.pageState,
        pageCommand: pageCommand,
        error: error,
        signupScreens: signupScreens ?? this.signupScreens,
        inviteModel: inviteModel ?? this.inviteModel,
        inviteMnemonic: inviteMnemonic ?? this.inviteMnemonic,
        fromDeepLink: fromDeepLink ?? this.fromDeepLink,
        accountName: accountName ?? this.accountName,
        displayName: displayName ?? this.displayName,
      );

  factory SignupState.initial() {
    return const SignupState(
      pageState: PageState.initial,
      signupScreens: SignupScreens.displayName,
      fromDeepLink: false,
    );
  }
}
