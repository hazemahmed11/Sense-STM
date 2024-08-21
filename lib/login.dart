
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sense_stm/register.dart';
import 'fire_auth.dart';
import 'main.dart';
import 'dart:io';




class FileManager {
  static final FileManager _instance = FileManager._internal();

  String? fileContent;
  String? uid;

  factory FileManager() {
    return _instance;
  }

  FileManager._internal();
}


class loginPage extends StatefulWidget {
  @override
  _loginPageState createState() => _loginPageState();
  }
class _loginPageState extends State<loginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();


  Future<void>_login() async{

    String email= _userController.text+ '@mobile.com';
    UserManager.username = _userController.text;
    String password=_passController.text;
    User? user=await _authService.signInWithEmailAndPassword(email, password);
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage(title: 'Your Sensor Configurations')),
      );
      print('Sign in successful: ${user.email}');
      ScaffoldMessenger.of(context).showSnackBar((SnackBar(content: Text('Logged in!'), duration: Duration(seconds: 1),)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username and Password invalid.', style: TextStyle(color: Colors.red),)));
      // Show error message
      print('Sign in failed');
      print(password);
    }

}


  //example text:
  //username:01066414047 password:123456 Sensor=DHT22 id=1 maxtmp=2 mintmp=3 token=hio threshold=5 timer=10 name=yep door=No, username:01003080758 password:123456 Sensor=DALLAS id=5 maxtmp=9 mintmp=6 token=hio threshold=100 timer=10 name=yep door=No,


  Future<void> _pickFileAndProcess() async {
    String? uid;
    String email;
    String password;
    User? user;

      // Pick the file
      String? filePath = await FilePicker.platform.pickFiles().then((
          result) => result?.files.single.path);

      if (filePath == null) return;


      String fileContent = await _readFile(filePath);
      print(fileContent);


      while (fileContent.contains(',')) {

        int commaIndex = fileContent.indexOf(',');

        String file2 = fileContent.substring(0, commaIndex).trim();
        print(file2);
        fileContent = fileContent.substring(commaIndex + 1).trim();


      Map<String, dynamic> data = await parseFileForCredentials(file2);


      email = data['username'] + '@mobile.com';
      UserManager.username = _userController.text;
      password = data['password'];
      user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        uid = user?.uid;

        FileManager().fileContent = file2;
        FileManager().uid = uid;

        await Navigator.push(context, MaterialPageRoute(builder: (context) =>
            MyHomePage(title: 'Your Sensor Configurations',
              fileContent: file2, uid: uid,
              )));

        print('Executed after 2 seconds');
  await _authService.signOut();

      }


    }

  }

  Future<String> _readFile(String path) async {

    return await File(path).readAsString();
  }


  Future<Map<String, String>> parseFileForCredentials(String fileContent) async {
    Map<String, String> data = {};


    List<String> parts = fileContent.split(' ');


    for (String part in parts) {
      if (part.startsWith('username:')) {
        data['username'] = part.split(':')[1].trim();
      } else if (part.startsWith('password:')) {
        data['password'] = part.split(':')[1].trim();
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In'),
      )
      ,
      body: Center(
        child: Column(
          children: [
            Text('Login with your phone number'),
            TextField(
              controller: _userController,
              decoration:
              InputDecoration(
                labelText: 'Phone Number',
                border: UnderlineInputBorder(),
              ),
            ),
            TextField(
              controller: _passController,
              decoration:
              InputDecoration(
                labelText: 'Password',
                border: UnderlineInputBorder(),
              ),
            ),
            ElevatedButton(onPressed: () {
              _login();
              if ((_userController.text.isEmpty) || (_passController.text.isEmpty) || !UserManager.userExists(_userController.text)){
                Text('Username or password invalid',
                  style: TextStyle(color: Colors.red, fontSize: 14),);
              }
              else{
                SnackBar(content: Text('Logged in!'),
                  duration: Duration(seconds: 1),

                );

              }
            }, child: Text('Login')),

            TextButton(onPressed: (){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegisterPage()));

            }, child:
            Text('No account? Register here!')),

            TextButton(onPressed: (){
              _pickFileAndProcess();

            }, child:
            Text('Add file')),

          ],),
      ),

    );
  }


}



