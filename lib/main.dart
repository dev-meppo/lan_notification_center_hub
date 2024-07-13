import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'in_app_notification.dart';
import 'lan_notification.dart';
import 'master_hub.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.system,
      /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class ClientInfo {
  ClientInfo({
    required this.name,
    required this.ip,
  });

  final String name;
  final String ip;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'ip': ip,
      };
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> logList = [];
  final List<ClientInfo> connectedClients = [];
  final Map<WebSocketChannel, ClientInfo> clientConnections = {};

  ClientInfo? clientInfo;
  String? myIP;
  late MasterHub masterHub;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyIP();
    init();
  }

  getMyIP() async {
    var result = await getMyLocalIp();

    if (result != null) {
      setState(() {
        myIP = result.address;
      });
    }
  }

  Future<void> init() async {
    masterHub = MasterHub(onNotification: (notif) {
      print('New notif!');
      setState(() {});
    }, onClientConnection: () {
      setState(() {});
    }, onClientClose: () {
      setState(() {});
    });

    masterHub.start();
  }

  Widget connectedClientsWidget() {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: Text(masterHub.connectedClients.length.toString()),
        title: Text('Connected Devices'),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: masterHub.connectedClients.length,
              itemBuilder: (context, index) {
                return Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(15),
                  child: ListTile(
                    title: Text(masterHub.connectedClients[index].name),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget logWidget() {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Text('Logs'),
        subtitle: Text(
          'Server logs are shown below.',
          style: TextStyle(fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: masterHub.logList.length,
              itemBuilder: (context, index) {
                return Material(
                  borderRadius: BorderRadius.circular(15),
                  elevation: 2,
                  child: ListTile(
                    leading: Text(masterHub.connectedClients.length.toString()),
                    title: Text(masterHub.logList[index]),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Hub Master ($myIP)'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              logWidget(),
              connectedClientsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

bool isInitialSetupMessage(dynamic message) {
  // Define your convention to identify initial setup message
  // For example, you can check if the message starts with a specific keyword
  // or contains a specific flag
  // Here, we assume that initial setup messages are JSON-encoded
  // and start with '{"type":"initial"}'
  if (message is String) {
    try {
      var decodedMessage = json.decode(message);
      return decodedMessage is Map<String, dynamic> &&
          decodedMessage['type'] == 'initial';
    } catch (e) {
      // JSON decoding error, not an initial setup message
      return false;
    }
  }
  return false;
}

Future<InternetAddress?> getMyLocalIp() async {
  final interfaceList = await NetworkInterface.list();
  final netInterface = interfaceList.first;

  for (var address in netInterface.addresses) {
    if (address.type == InternetAddressType.IPv4) {
      return address;
    }
  }

  return null;
}
