# Hashed Wallet - A Social Recovery Wallet for Polkadot

## Systems And Platforms Used

[Flutter](https://flutter.dev/) for cross platform mobile development.

[Polkadot JS](https://polkadot.js.org) for API calls into substrate compatible blockchains


## Architecture and Approach

### Polkadot JS
Polkadot JS runs inside a hidden web view - both Android and iOS have the capability to run JavaScript code. 

A build of Polkadot JS is packaged with webpack and delivered with the app. 

The source code for the JavaScript build is in [/assets/polkadot/sdk/js_api](https://github.com/hypha-dao/hashed-wallet/tree/v1.0.0_M1_00/assets/polkadot/sdk/js_api) and based on the approach and code used in Polkawallet

### Flutter Application

We use the [BLoC](https://www.raywenderlich.com/31973428-getting-started-with-the-bloc-pattern) pattern with several additions and improvements for state management. [Flutter Bloc Package](https://pub.dev/packages/flutter_bloc)


Business logic happens in BLoC components. 

Drawing happens in Widgets

State is kept in State objects

APIs are accessed through local or remote repositories - example polkadot_repository.dart contains all remote API calls for polkadot. Every repository call returns a success or failure result, which is then added to the state, and subsequencly rendered in the user interface (which renders the state).

Use cases abstract actions that are asynchronous. 

Private keys are kept in secure storage on both platforms. 

### Milestone 1 Codebase

All code is formatted according to Flutter/Dart recommended linter settings. The only exception to this is third party code that was included as-is in, such as some code from Polkawallet, and some crypto libraries. 

Polkawallet code was included as source code because we only use it as template and guideline and streamline it once all features are working. 

Code has not been cleaned yet of EOSIO access code. This is because there is still some user interface code we will reuse, and adapt for polkadot. Once we are feature complete we will remove all EOSIO and other legacy "Seeds Light Wallet" code from the wallet. Probably at Milestone 2. 

The new code is visible in the screens - startup screen, sign in screen, create account screen, Settings screen, and guardians screen. 

While we would love to remove all unused code now, it would cause more work later on when we have to add bits and pieces back, so we decided to hold off on it now. 

Same for inline documentation - removing legacy code, or doing work in order to have a better and cleaner documentation for this milestone will cause more work for the next milestone when we have to add in some of the code again. The codebase will be cleaned in Milestone 2. 


