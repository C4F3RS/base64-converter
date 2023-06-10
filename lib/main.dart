import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

setScreenSize() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    Size windowsSize = const Size(400, 400);
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
        size: windowsSize,
        maximumSize: windowsSize,
        minimumSize: windowsSize,
        center: true,
        fullScreen: false,
        backgroundColor: Colors.transparent,
        title: "Base64 Converter");
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

requestStoragePermission() async {
  if (Platform.isAndroid || Platform.isIOS) {
    await Permission.storage.request();
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await setScreenSize();
  await requestStoragePermission();
  runApp(MaterialApp(
      title: "base64 converter",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: Typography.whiteMountainView),
      home: const App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final textFieldController = TextEditingController();
  bool isProgress = false;
  String progressStatus = "";

  convertErrorAlert() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
              backgroundColor: Colors.grey.shade900,
              content: const Text(
                "convert error",
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("ok"))
              ]));

  toBase64Progress() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      log(result.toString());
      setState(() {
        isProgress = true;
        progressStatus = "encoding...";
      });
      try {
        for (var file in result.files) {
          await File("${file.path}.base64.txt").create();
          await File("${file.path}.base64.txt").writeAsString(
              base64Encode(await File(file.path!).readAsBytes()));
          log("yazma bitti ${DateTime.now()}");
          await File(file.path!).delete();
        }
      } on FileSystemException catch (_) {
        convertErrorAlert();
      }
      setState(() {
        isProgress = false;
        progressStatus = "";
      });
    }
  }

  fromBase64Progress() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      log(result.toString());
      setState(() {
        isProgress = true;
        progressStatus = "decoding...";
      });
      try {
        for (var file in result.files) {
          await File(file.path!.replaceFirst(".base64.txt", "")).create();
          await File(file.path!.replaceFirst(".base64.txt", "")).writeAsBytes(
              base64Decode(await File(file.path!).readAsString()));
          await File(file.path!).delete();
        }
      } on FileSystemException catch (_) {
        convertErrorAlert();
      }
      setState(() {
        isProgress = false;
        progressStatus = "";
      });
    }
  }

  Widget get toBase64 => ElevatedButton(
      onPressed: isProgress ? null : toBase64Progress,
      child: const Text("Encode to base64"));

  Widget get fromBase64 => ElevatedButton(
      onPressed: isProgress ? null : fromBase64Progress,
      child: const Text("Decode to base64"));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            toBase64,
            if (isProgress) Text(progressStatus),
            fromBase64
          ],
        ),
      ),
    ));
  }
}
