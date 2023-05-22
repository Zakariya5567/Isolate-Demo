import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

//
// void isolateFunction(int finalNum) {
//   int _count = 0;
//
//   for (int i = 0; i < finalNum; i++) {
//     _count++;
//     if ((_count % 100) == 0) {
//       print("isolate: " + _count.toString());
//     }
//   }
// }

// computeFunction(int finalNum) {
//   int _count = 0;
//
//   for (int i = 0; i < finalNum; i++) {
//     _count++;
//     if ((_count % 100) == 0) {
//       print("compute: " + _count.toString());
//     }
//   }
//   // return _count;
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  //============================================================================
  // isolate function

  static void isolateFunction(int finalNum) {
    int count = 0;

    for (int i = 0; i < finalNum; i++) {
      count++;
      if ((count % 100) == 0) {
        debugPrint("isolate: $count");
      }
    }
  }

  //============================================================================
  // compute function
  static int computeFunction(int finalNum) {
    int count = 0;

    for (int i = 0; i < finalNum; i++) {
      count++;
      if ((count % 100) == 0) {
        debugPrint("compute: $count");
      }
    }
    return count;
  }

  //==============================================================================
  //Api calling with compute
  Future<void> createComputeFunction() async {
    var response =
        await compute(computeApiFunction, "https://randomuser.me/api/");
    debugPrint("Result: ${response.body}");
  }

  static Future<http.Response> computeApiFunction(String url) async {
    var response = await http.get(Uri.parse(url));
    return response;
  }

  //==============================================================================
  //Api calling with isolate
  Future createIsolate() async {
    ReceivePort receivePort = ReceivePort();
    Isolate.spawn(isolateApiFunction, receivePort.sendPort);

    SendPort childSendPort = await receivePort.first;

    ReceivePort responsePort = ReceivePort();
    childSendPort.send(["https://randomuser.me/api/", responsePort.sendPort]);

    var response = await responsePort.first;
    debugPrint("Response : $response");
  }

  static void isolateApiFunction(SendPort mainSendPort) async {
    ReceivePort childReceivePort = ReceivePort();

    mainSendPort.send(childReceivePort.sendPort);

    await for (var message in childReceivePort) {
      String url = message[0];
      SendPort replyPort = message[1];
      var response = await http.get(Uri.parse(url));
      replyPort.send(jsonDecode(response.body));
    }
  }

  //==============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
            const SizedBox(
              width: 10,
            ),
            FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  Isolate.spawn(isolateFunction, 1000);
                },
                tooltip: 'Isolate',
                child: const Text("isolate")),
            const SizedBox(
              width: 10,
            ),
            FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () async {
                  await compute(computeFunction, 2000);
                },
                tooltip: 'compute',
                child: const Text("comput")),
            const SizedBox(
              width: 10,
            ),
            FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  createComputeFunction();
                },
                tooltip: 'Api with compute',
                child: const Text("Api C")),
            const SizedBox(
              width: 10,
            ),
            FloatingActionButton(
                backgroundColor: Colors.orange,
                onPressed: () {
                  createIsolate();
                },
                tooltip: 'Api with isolate',
                child: const Text("Api Is")),
          ],
        ));
  }
}
