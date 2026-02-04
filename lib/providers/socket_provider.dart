// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../services/socket_service.dart';

// /// Provider for tracking socket connection status
// final socketStatusProvider = StreamProvider<bool>((ref) {
//   // Use the connectionStream from SocketService
//   return SocketService.instance.connectionStream;
// });

// /// Provider for manual connection check (synchronous)
// final isSocketConnectedProvider = Provider<bool>((ref) {
//   // Watch the stream provider to get updates
//   final status = ref.watch(socketStatusProvider);
//   return status.when(
//     data: (connected) => connected,
//     loading: () => SocketService.instance.isConnected,
//     error: (_, __) => false,
//   );
// });
