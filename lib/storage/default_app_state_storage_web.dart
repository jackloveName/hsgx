import 'app_state_storage.dart';

AppStateStorage createDefaultAppStateStorage() =>
    SharedPreferencesAppStateStorage();
