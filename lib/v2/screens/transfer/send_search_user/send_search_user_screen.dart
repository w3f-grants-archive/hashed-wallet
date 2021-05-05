import 'package:flutter/material.dart';
import 'package:seeds/v2/components/search_user/search_user_widget.dart';
import 'package:seeds/v2/datasource/remote/model/member_model.dart';
import 'package:seeds/v2/navigation/navigation_service.dart';

/// SendSearchUserScreen SCREEN
class SendSearchUserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future<void> onResult(MemberModel selectedUser) async {
      print("onResult:" + selectedUser.account);
      await NavigationService.of(context).navigateTo(Routes.sendEnterData, selectedUser);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Send")),
      body: Container(padding: const EdgeInsets.all(16), child: SearchUserWidget(resultCallBack: onResult)),
    );
  }
}
