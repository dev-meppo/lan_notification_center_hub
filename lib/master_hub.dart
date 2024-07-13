import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'lan_notification.dart';
import 'main.dart';

class MasterHub {
  MasterHub({
    required this.onNotification,
    required this.onClientConnection,
    required this.onClientClose,
  });

  Future<void> start() async {
    ClientInfo clientInfo = ClientInfo(
      name: '',
      ip: '',
    );
    var wsHandler = webSocketHandler(
      pingInterval: const Duration(seconds: 10),
      (WebSocketChannel webSocket) {
        print('Client connected.');

        wsChannel = webSocket;

        wsChannel.stream.listen(
          (message) {
            var decodedJson = json.decode(message);
            String eventType = decodedJson['type'];

            switch (eventType) {
              case 'initial':
                _newClientHandler(decodedJson);

              case 'notif_req':
                _notificationRequestHandler(decodedJson);

              default:
                if (kDebugMode) {
                  print('Could not handle event type: $eventType');
                }
            }
          },
          onDone: () {
            // Remove the client when the connection is closed
            connectedClients.remove(clientInfo);
            clientConnections.remove(webSocket);
            onClientClose();
            print('Removed client: ${webSocket.hashCode}');
          },
        );
      },
    );

    // HTTP handler
    var httpHandler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler((Request request) {
      if (request.method == 'GET' && request.requestedUri.path == '/clients') {
        var clientsJson = json.encode(connectedClients);
        if (kDebugMode) {
          print('Returning ${connectedClients.length} clients.');
        }
        return Response.ok(clientsJson,
            headers: {'Content-Type': 'application/json'});
      }
      return Response.notFound('Not Found');
    });

    // Combine WebSocket and HTTP handlers
    var cascade = Cascade().add(wsHandler).add(httpHandler);

    // Start the server
    var server =
        await io.serve(cascade.handler, InternetAddress.anyIPv4, 53123);
    print('Server listening on port ${server.port}');
  }

  /// Handles new client that are connecting to notification center.
  void _newClientHandler(dynamic decodedJson) {
    // Handle initial setup message
    var clientIp = decodedJson['clientIp'];
    var identifier = decodedJson['identifier'];

    updateLog('Initial message\n ${decodedJson}');

    if (clientIp == null || identifier == null) {
      wsChannel.sink.add('Error: Required metadata missing');
      wsChannel.sink.close();
      return;
    }

    var clientInfo = ClientInfo(
      name: identifier,
      ip: clientIp,
    );
    connectedClients.add(clientInfo);
    clientConnections[wsChannel] = clientInfo;

    // Additional processing for initial setup message...

    if (kDebugMode) {
      print('');

      print('---_newClientHandler()---');
      print('Handling new client: ${clientInfo.name}');

      print('---_newClientHandler()---');
      print('');
    }
  }

  /// Handles notification requests from clients.
  void _notificationRequestHandler(dynamic notifReqJson) {
    // Handle notification message
    try {
      var notification = LanNotificationRequest.fromJson(notifReqJson);

      print(
          'Notification: ${notification.title}, ${notification.content}, ${notification.recipientAddress}, ${notification.id}');

      // Distribute the notification to all clients
      notificationDistributor(notification);
      onNotification(notification);
    } catch (e) {
      print('Error parsing message: $e');
      wsChannel.sink.add('Error: Invalid message format');
    }
  }

  void distributeNotificationToAll(LanNotification notification) {
    for (var client in clientConnections.keys) {
      client.sink.add(json.encode(notification.toJson()));
    }

    if (kDebugMode) {
      print("---distributeNotificationToAll()---");

      print(
          'Sending notification to all connected clients: ${clientConnections.length}.');

      print("---distributeNotificationToAll()---");
    }
  }

  /// Handles the notification distribution to clients.
  void notificationDistributor(LanNotification notification) {
    if (notification.recipientAddress.isNotEmpty) {
      if (notification.recipientAddress.first == '*') {
        distributeNotificationToAll(notification);

        return;
      }
    }

    // Distribute only to selected clients.

    if (kDebugMode) {
      print("notificationHandler()");

      print("Unkwon recipient address: ${notification.recipientAddress}");

      print("notificationHandler()");
    }
  }

  void updateLog(String value) {
    logList.add(value);
    onClientConnection();
  }

  List<String> logList = [];
  final List<ClientInfo> connectedClients = [];
  final Map<WebSocketChannel, ClientInfo> clientConnections = {};
  final Function(LanNotification) onNotification;
  final Function() onClientConnection;
  final Function() onClientClose;

  late WebSocketChannel wsChannel;
}
