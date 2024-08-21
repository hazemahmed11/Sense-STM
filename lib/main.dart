import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:sense_stm/register.dart';
import 'package:sense_stm/thingsboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'dart:convert';
import 'graphs.dart';
import 'http_conn.dart';
import 'package:readsms/readsms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class UserData {
  final int id;
  final int mintmp;
  final int maxtmp;
  final int timer;
  final String token;
  final int thrtimer;
  final Object? indxx;
  final String? Sensor;
  final String name;
  final String? door;

  UserData(
      {required this.id,
      required this.thrtimer,
      required this.maxtmp,
      required this.mintmp,
      required this.token,
      required this.timer,
      required this.indxx,
      required this.Sensor,
      required this.name,
      required this.door,});
}

class datal {
  static final List<List<UserData>> _data = [];
  static met(List<UserData> userDataList) {
    _data.add(userDataList);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sense-STM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal.shade800),
        useMaterial3: true,
      ),
      home: RegisterPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title, this.fileContent, this.uid});

  final String title;
  String? fileContent;
  String? uid;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _idcontrol = TextEditingController();
  final TextEditingController _tokencontrol = TextEditingController();
  final TextEditingController _mintmp = TextEditingController();
  final TextEditingController _maxtmp = TextEditingController();
  final TextEditingController _thresholdcontrol = TextEditingController();
  final TextEditingController _timercontrol = TextEditingController();
  final TextEditingController _sensorcontrol = TextEditingController();
  final TextEditingController _passcontrol = TextEditingController();
  final TextEditingController _ssidcontrol = TextEditingController();
  final TextEditingController _namecontrol = TextEditingController();
  final TextEditingController _doorcontrol = TextEditingController();
  String? _select;
  String? _door;
  int count = 0;
  List<String> recipients = [UserManager.username];
  late final MqttService _mqttService;
  Map<String, dynamic> sensorData = {};
  Map<String, dynamic> sensorData2 = {};
  late HttpService _httpService;
  Telephony telephony = Telephony.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String? uid;
  final _plugin = Readsms();
  String sms = 'no sms received';
  String sender = 'no sms received';
  String time = 'no sms received';

  @override
  void initState() {
    super.initState();
    uid = user?.uid;
    _load();
    if (widget.fileContent != null) {
      wait();
    }
    _mqttService = MqttService(
      accessToken: '',
      onMessageReceived: (data2) {
        setState(() {
          sensorData2 = data2;
        });
      },
    );
    _httpService = HttpService(
      accessToken: '',
      onMessageReceived: (data) {
        print('Received data: $data');
        setState(() {
          sensorData = data;
        });
      },
    );
    _plugin.read();
    _plugin.smsStream.listen((event) {
      setState(() {
        sms = event.body;
        sender = event.sender;
        time = event.timeReceived.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Received SMS: ${sms}"),
              duration: Duration(seconds: 5)),
        );
      });
    });
  }


  @override
  void dispose() {
    super.dispose();
    _mqttService.disconn();


  }

  Future<void> wait() async {
    await addConfigurationsFromFile(widget.fileContent, widget.uid);

    if (mounted) {

      await Future.delayed(Duration(seconds: 2));

      // Sign out and navigate back to the login page
      if (mounted) {
        Navigator.pop(context, MaterialPageRoute(builder: (context) => loginPage()));
      }
    }
  }


  //example text:
  //username:01066414047 password:123456 Sensor=DHT22 id=1 maxtmp=2 mintmp=3 token=hio threshold=5 timer=10 name=yep door=No

  Future<void> _addConfigurationsFromFile() async {
    String? filePath = await _pickFile();
    if (filePath == null) return;

    String fileContent = await _readFile(filePath);
    if (fileContent.isEmpty) return;

    List<UserData> newConfigurations = _parseCustomFormat(fileContent);


    setState(() {
      if (datal._data.isEmpty || datal._data[UserManager.userIndex] == null) {
        datal._data.add([]);
      }

      datal._data[UserManager.userIndex].addAll(newConfigurations);
    });

    SharedPreferences pref = await SharedPreferences.getInstance();
    List<String> userDataS = datal._data[UserManager.userIndex].map((userData) {
      return jsonEncode({
        'id': userData.id,
        'token': userData.token,
        'mintmp': userData.mintmp,
        'maxtmp': userData.maxtmp,
        'threshold': userData.thrtimer,
        'timer': userData.timer,
        'indxx': userData.indxx,
        'Sensor': userData.Sensor,
        'name': userData.name,
        'door': userData.door
      });
    }).toList();

    await pref.setStringList(uid!, userDataS);
    print('complete!');

  }

  List<UserData> _parseCustomFormat(String content) {
    List<UserData> userDataList = [];
    Object indxx = count;


    List<String> configurations = content.split(',');

    for (String config in configurations) {
      String trimmedConfig = config.trim();
      if (trimmedConfig.isEmpty) continue;


      Map<String, String> configMap = {};
      List<String> parts = trimmedConfig.split(' ');
      for (String part in parts) {
        List<String> keyValue = part.split('=');
        if (keyValue.length == 2) {
          configMap[keyValue[0]] = keyValue[1];
        }
      }

      if (configMap['Sensor'] == 'DALLAS') {
        count += 1;
      }


      UserData newUserData = UserData(
        id: int.parse(configMap['id'] ?? '0'),
        thrtimer: int.parse(configMap['threshold'] ?? '0'),
        maxtmp: int.parse(configMap['maxtmp'] ?? '0'),
        mintmp: int.parse(configMap['mintmp'] ?? '0'),
        token: configMap['token'] ?? '',
        timer: int.parse(configMap['timer'] ?? '0'),
        indxx: indxx,
        Sensor: configMap['Sensor'],
        name: configMap['name'] ?? '',
        door: configMap['door'] ?? '',

      );
      userDataList.add(newUserData);
    }

    return userDataList;
  }
//this uses given files from other classes
  Future<void> addConfigurationsFromFile(String? fileContent, String? uid) async {

    List<UserData> newConfigurations = parseCustomFormat(fileContent!);

    setState(() {
      if (datal._data.isEmpty || datal._data[UserManager.userIndex] == null) {
        datal._data.add([]);
      }

      datal._data[UserManager.userIndex].addAll(newConfigurations);
    });

    SharedPreferences pref = await SharedPreferences.getInstance();
    List<String> userDataS = datal._data[UserManager.userIndex].map((userData) {
      return jsonEncode({
        'id': userData.id,
        'token': userData.token,
        'mintmp': userData.mintmp,
        'maxtmp': userData.maxtmp,
        'threshold': userData.thrtimer,
        'timer': userData.timer,
        'indxx': userData.indxx,
        'Sensor': userData.Sensor,
        'name': userData.name,
        'door': userData.door
      });
    }).toList();

    await pref.setStringList(uid!, userDataS);
    print(uid);

  }

  List<UserData> parseCustomFormat(String content) {
    List<UserData> userDataList = [];
    Object indxx = count;


    List<String> configurations = content.split(',');

    for (String config in configurations) {
      String trimmedConfig = config.trim();
      if (trimmedConfig.isEmpty) continue;

      // Parse each configuration
      Map<String, String> configMap = {};
      List<String> parts = trimmedConfig.split(' ');
      for (String part in parts) {
        List<String> keyValue = part.split('=');
        if (keyValue.length == 2) {
          configMap[keyValue[0]] = keyValue[1];
        }
      }

      if (configMap['Sensor'] == 'DALLAS') {
        count += 1;
      }

      // Create UserData object
      UserData newUserData = UserData(
        id: int.parse(configMap['id'] ?? '0'),
        thrtimer: int.parse(configMap['threshold'] ?? '0'),
        maxtmp: int.parse(configMap['maxtmp'] ?? '0'),
        mintmp: int.parse(configMap['mintmp'] ?? '0'),
        token: configMap['token'] ?? '',
        timer: int.parse(configMap['timer'] ?? '0'),
        indxx: indxx,
        Sensor: configMap['Sensor'],
        name: configMap['name'] ?? '',
        door: configMap['door'] ?? '',
      );
      userDataList.add(newUserData);
    }

    return userDataList;
  }


  Future<String?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return result.files.single.path;
    }
    return null;
  }

  Future<String> _readFile(String filePath) async {
    try {
      return await File(filePath).readAsString();
    } catch (e) {
      print('Error reading file: $e');
      return '';
    }
  }

  Future<void> _saveConf() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    List<String> userDataS = datal._data[UserManager.userIndex].map((userData) {
      return jsonEncode({
        'id': userData.id,
        'token': userData.token,
        'mintmp': userData.mintmp,
        'maxtmp': userData.maxtmp,
        'threshold': userData.thrtimer,
        'timer': userData.timer,
        'indxx': userData.indxx,
        'Sensor': userData.Sensor,
        'name': userData.name,
        'door': userData.door,

      });
    }).toList();
    await pref.setStringList(uid!, userDataS);
    print('Data saved to SharedPreferences: $userDataS');
    print(UserManager.userIndex);
    print(_select);

    if (_select == 'DALLAS') {
      _sendsms(userDataS);
    } else if (_select == 'DHT22') {
      _dhtsms(userDataS);
    } else {
      _shtsms(userDataS);
    }
  }

  Future<void> _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userDataS = prefs.getStringList(uid!);
    //prefs.clear();
    if (userDataS != null) {
      while (datal._data.length <= UserManager.userIndex) {
        datal._data.add([]);
      }
      datal._data[UserManager.userIndex].addAll(userDataS.map((userDataJson) {
        Map<String, dynamic> userDataMap = jsonDecode(userDataJson);
        return UserData(
            id: userDataMap['id'],
            thrtimer: userDataMap['threshold'],
            maxtmp: userDataMap['maxtmp'],
            mintmp: userDataMap['mintmp'],
            token: userDataMap['token'],
            timer: userDataMap['timer'],
            indxx: userDataMap['indxx'],
            Sensor: userDataMap['Sensor'],
            name: userDataMap['name'],
            door: userDataMap['door'],
         );
      }).toList());
      setState(() {});
    }
    print('Data saved to SharedPreferences: $userDataS');
  }

  void _sendsms(List<String> userDataS) async {
    String message = '';
    for (String j in userDataS) {
      Map<String, dynamic> m = jsonDecode(j);
      message +=
          '#!ID: ${m['id']} ,Token:${m['token']}, Timer:${m['timer']},Thtimer:${m['threshold']} Min:${m['mintmp']}, Max:${m['maxtmp']},  Index:${m['indxx']}!#';
    }
    try {
      sendSMS(message: message, recipients: recipients, sendDirect: true);
      print('SMS sent successfully');
      print(recipients);
    } catch (error) {
      print('Failed to send SMS: $error');
    }
  }

  void _dhtsms(List<String> userDataS) async {
    String msg = '';
    for (String j in userDataS) {
      Map<String, dynamic> m = jsonDecode(j);
      msg +=
          '%D\$H#T!ID: ${m['id']} ,Token:${m['token']}, Timer:${m['timer']},Thtimer:${m['threshold']} Min:${m['mintmp']}, Max:${m['maxtmp']}!D#H\$T%';
    }
    try {
      sendSMS(message: msg, recipients: recipients, sendDirect: true);
    } catch (error) {
      print('Failed to send SMS: $error');
    }
  }

  void _shtsms(List<String> userDataS) async {
    String mess = '';
    for (String j in userDataS) {
      Map<String, dynamic> m = jsonDecode(j);
      mess +=
          '%S\$H#T!ID: ${m['id']} ,Token:${m['token']}, Timer:${m['timer']},Thtimer:${m['threshold']} Min:${m['mintmp']}, Max:${m['maxtmp']}  !S#H\$T%';
    }
    try {
      sendSMS(message: mess, recipients: recipients, sendDirect: true);
    } catch (error) {
      print('Failed to send SMS: $error');
    }
  }

  void _show() async {
    String msg = '&#!SHOW_CONFIGS!#&';
    List<String> recipient = [UserManager.username];
    try {
      sendSMS(
          message: msg,
          recipients: recipient,
          sendDirect: true); // Replace with your recipient's phone number
      print('SMS sent successfully');
      print(recipient);
    } catch (error) {
      print('Failed to send SMS: $error');
    }
  }

  void _connect() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Choose your connection'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextButton(
                      onPressed: () {
                        sendSMS(
                            message: '!&%\$Wi-Fi\$%&',
                            recipients: recipients,
                            sendDirect: true);
                      },
                      child: Text('Wifi')),
                  TextButton(
                      onPressed: () {
                        sendSMS(
                            message: '!&%\$4G\$%&!',
                            recipients: recipients,
                            sendDirect: true);
                      },
                      child: Text('4G'))
                ],
              ),
            ),
          );
        });
  }

  void _save(BuildContext context, int? index) async {
    setState(() {
      String? Sensor = _select;
      String? door = _door;
      int id = int.parse(_idcontrol.text);
      int maxtmp = int.parse(_maxtmp.text);
      int mintmp = int.parse(_mintmp.text);
      String token = _tokencontrol.text;
      int threshold = int.parse(_thresholdcontrol.text);
      int timer = int.parse(_timercontrol.text);
      String name = _namecontrol.text;
      Object indxx = count;

      // Create a new UserData object
      UserData newUserData = UserData(
          id: id,
          thrtimer: threshold,
          maxtmp: maxtmp,
          mintmp: mintmp,
          token: token,
          timer: timer,
          indxx: indxx,
          Sensor: Sensor,
          name: name,
          door: door,
        );

      if (datal._data.isEmpty || datal._data[UserManager.userIndex] == null) {
        datal._data.add([]);
        // Add new configuration
        datal._data[UserManager.userIndex].add(newUserData);
      } else {
        // Update existing configuration
        if (index != null &&
            index >= 0 &&
            index < datal._data[UserManager.userIndex].length) {
          datal._data[UserManager.userIndex][index] = newUserData;
        } else {
          datal._data[UserManager.userIndex].add(newUserData);
        }
      }
    });
    _saveConf();
  }

  void _addConf(BuildContext context, [int? index]) async {
    _idcontrol.clear();
    _maxtmp.clear();
    _mintmp.clear();
    _tokencontrol.clear();
    _timercontrol.clear();
    _thresholdcontrol.clear();
    _sensorcontrol.clear();
    _namecontrol.clear();
    _doorcontrol.clear();

    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Configure this device'),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                DropdownButtonFormField<String>(
                  value: _select,
                  decoration: InputDecoration(
                    labelText: 'Sensor Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DHT22', child: Text('DHT22')),
                    DropdownMenuItem(value: 'SHT30', child: Text('SHT30')),
                    DropdownMenuItem(value: 'DALLAS', child: Text('DALLAS')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _select = newValue;
                    });
                  },
                ),
                    TextField(
                      controller: _namecontrol,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                TextField(
                  controller: _idcontrol,
                  decoration: InputDecoration(
                    labelText: 'ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _tokencontrol,
                  decoration: InputDecoration(
                    labelText: 'Access Token',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _mintmp,
                  decoration: InputDecoration(
                    labelText: 'Minimum temperature threshold',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _maxtmp,
                  decoration: InputDecoration(
                    labelText: 'Maximum temperature threshold',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _timercontrol,
                  decoration: InputDecoration(
                    labelText: 'timer',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _thresholdcontrol,
                  decoration: InputDecoration(
                    labelText: 'threshold',
                    border: OutlineInputBorder(),
                  ),
                ),
                    DropdownButtonFormField<String>(
                      value: _door,
                      decoration: InputDecoration(
                        labelText: 'Door',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                        DropdownMenuItem(value: 'No', child: Text('No')),

                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _door = newValue;
                        });
                      },
                    ),
              ])),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () {
                    _save(context, index);
                    if (_select == 'DALLAS') {
                      count += 1;
                    }

                    if (_door == 'Yes'){
                      sendSMS(message: 'Door is on', recipients: recipients, sendDirect: true);
                    }

                     Navigator.of(context).pop();
                    _mqttService.updateAccessToken(_tokencontrol.text);
                    _httpService.updateAccessToken(_tokencontrol.text);
                  },
                  child: Text('Save'),
                ),
                TextButton(
                    onPressed: () {
                      _addConfigurationsFromFile();
                      Navigator.of(context).pop();
                    },
                    child: Text('Add File'))
              ]);
        });
  }

  void _viewConf(BuildContext context, int index, [UserData? userData]) async {
    print(datal._data[UserManager.userIndex]);
    print(index);
    if (index >= 0) {
      UserData userData = datal._data[UserManager.userIndex][index]; //get the data of the conf index youre trying to access then set controllers to the values in that index.
      _idcontrol.text = userData.id.toString();
      _maxtmp.text = userData.maxtmp.toString();
      _mintmp.text = userData.mintmp.toString();
      _tokencontrol.text = userData.token.toString();
      _timercontrol.text = userData.timer.toString();
      _thresholdcontrol.text = userData.thrtimer.toString();
      _sensorcontrol.text = userData.Sensor.toString();
      _doorcontrol.text = userData.door.toString();
      _namecontrol.text = userData.name.toString();
      _mqttService.updateAccessToken(_tokencontrol.text);
      _httpService.updateAccessToken(_tokencontrol.text);
    }
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Configure this device'),
              content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                DropdownButtonFormField<String>(
                  value: _sensorcontrol.text,
                  decoration: InputDecoration(
                    labelText: 'Sensor Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DHT22', child: Text('DHT22')),
                    DropdownMenuItem(value: 'SHT30', child: Text('SHT30')),
                    DropdownMenuItem(value: 'DALLAS', child: Text('DALLAS')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _select = newValue;
                    });
                  },
                ),
                TextField(
                  controller: _namecontrol,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _idcontrol,
                  decoration: InputDecoration(
                    labelText: 'ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _tokencontrol,
                  decoration: InputDecoration(
                    labelText: 'Access Token',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _mintmp,
                  decoration: InputDecoration(
                    labelText: 'Minimum temperature threshold',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _maxtmp,
                  decoration: InputDecoration(
                    labelText: 'Maximum temperature threshold',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _timercontrol,
                  decoration: InputDecoration(
                    labelText: 'Timer',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _thresholdcontrol,
                  decoration: InputDecoration(
                    labelText: 'Threshold',
                    border: OutlineInputBorder(),
                  ),
                ),
                    DropdownButtonFormField<String>(
                      value: _doorcontrol.text,
                      decoration: InputDecoration(
                        labelText: 'Door',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                        DropdownMenuItem(value: 'No', child: Text('No')),

                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _door = newValue;
                        });
                      },
                    ),




              ])),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () {
                    _save(context, index);
                    Navigator.of(context).pop();
                    print(datal._data);
                    _mqttService.updateAccessToken(_tokencontrol.text);
                    _httpService.updateAccessToken(_tokencontrol.text);
                  },
                  child: Text('Save'),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'HTTP') {
                      print(_tokencontrol.text);
                      _httpService.startFetchingData();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraphPage(
                            httpService: _httpService,
                            mqttService: _mqttService,
                          ),
                        ),
                      );
                    } else if (value == 'MQTT') {
                      _mqttService.connect();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraphPage(
                            mqttService: _mqttService,
                            httpService: _httpService,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return {'HTTP', 'MQTT'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
        // Column is also a layout widget. It takes a list of children and
        // arranges them vertically. By default, it sizes itself to fit its
        // children horizontally, and tries to be as tall as its parent.
        //
        // Column has various properties to control how it sizes itself and
        // how it positions its children. Here we use mainAxisAlignment to
        // center the children vertically; the main axis here is the vertical
        // axis because Columns are vertical (the cross axis would be
        // horizontal).
        //
        // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
        // action in the IDE, or press "p" in the console), to see the
        // wireframe for each widget.
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          datal._data.isEmpty || datal._data[UserManager.userIndex].isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('No configurations available :(')],
                )
              : Expanded(
                  child: GridView.builder(
                  itemCount: datal._data[UserManager.userIndex].length,
                  itemBuilder: (context, index) {
                    UserData userData =
                        datal._data[UserManager.userIndex][index];

                    return GestureDetector(
                        onTap: () {
                          _viewConf(context, index, userData);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                              //userData.Sensor == 'DALLAS'
                                //  ? '${userData.Sensor} ${userData.indxx}'
                                //  : '${userData.Sensor}'.
                                       '${userData.name} ',

                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ));
                  },
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                ))
        ],
      )),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _addConf(context);
              },
              tooltip: 'Add Configuration',
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 16.0, // Adjust the distance from the bottom
            right: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _show();
              },
              tooltip: 'Show',
              child: const Icon(Icons.remove_red_eye_outlined),
            ),
          ),
          Positioned(
              bottom: 100.0,
              right: 16.0,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  _connect();
                },
                tooltip: 'WiFi',
                child: const Icon(Icons.wifi),
              )),
          Positioned(
              bottom: 16.0,
              left: 32.0,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () async {
                  SharedPreferences pref =
                      await SharedPreferences.getInstance();
                  pref.remove(uid!);
                  count = -1;
                  _load();
                  datal._data.clear();
                  setState(() {
                    _load();
                  });
                  sendSMS(
                      message: '&#!RESET_CONFIGS!#&',
                      recipients: recipients,
                      sendDirect: true);
                },
                tooltip: 'Reset',
                child: const Icon(Icons.refresh),
              )),
          Positioned(
              bottom: 100.0,
              left: 32.0,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                              child: ListBody(
                            children: <Widget>[
                              TextField(
                                controller: _ssidcontrol,
                                decoration: InputDecoration(
                                  labelText: 'SSID',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              TextField(
                                controller: _passcontrol,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              TextButton(
                                  onPressed: () {
                                    sendSMS(
                                        message: '#\$SSID:' +
                                            _ssidcontrol.text +
                                            ',PWD:' +
                                            _passcontrol.text +
                                            '\$#',
                                        recipients: recipients,
                                        sendDirect: true);
                                  },
                                  child: Text('Send'))
                            ],
                          )),
                        );
                      });
                },
                tooltip: 'Connect',
                child: const Icon(Icons.connect_without_contact),
              )),
        ],
      ),
    );
  }
}


