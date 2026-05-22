import 'ws_client.dart';

import 'ws_client_stub.dart' if (dart.library.html) 'ws_client_web.dart' if (dart.library.io) 'ws_client_io.dart';

WsClient createWsClient() => createClient();
