import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seeds/models/models.dart';
import 'package:seeds/providers/services/http_service.dart';
import 'package:provider/provider.dart';

class PlantedNotifier extends ChangeNotifier {
  PlantedModel balance;

  HttpService _http;

  static of(BuildContext context, {bool listen = false}) =>
      Provider.of<PlantedNotifier>(context, listen: listen);

  void update({ HttpService http }) {
    _http = http;
  }

  void fetchBalance() {
    _http.getPlanted().then((result) {
      balance = result;
      notifyListeners();
    });
  }
}
