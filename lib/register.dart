import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sense_stm/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fire_auth.dart';
import 'main.dart';



class logdata{
  final String no;
  final String password;

  logdata(
      {required this.no,
        required this.password}
      );
}
class UserManager {

  static final UserManager _instance = UserManager._internal();

  static String username = '';
  static String password = '';

  factory UserManager() {
    return _instance;
  }
  UserManager._internal();
  static int userIndex = 0;
  static final List<logdata> _users = [];

  static int dex(){
    return userIndex;
  }
  static List<logdata> get users => _users;

  static void addUser(logdata user) {
    _users.add(user);
    datal.met([]);

  }

  static bool userExists(String username) {
    return _users.any((user) => user.no == username);
  }
  static info(){

  }
}

class RegisterPage extends StatefulWidget{
  @override
  _RegisterPageState createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up'),
      )
      ,
      body: Center(
        child: Column(
            children: [
              Text('Register your phone number'),
              TextField(
                controller: _usernameController,
                decoration:
                InputDecoration(
                  labelText: 'Phone Number',
                  border: UnderlineInputBorder(),
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration:
                InputDecoration(
                  labelText: 'Password',
                  border: UnderlineInputBorder(),
                ),
              ),
              ElevatedButton(onPressed: () {
                  _reg();

              }, child: Text('Register')),

              TextButton(onPressed: (){

                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => loginPage()));

              }, child:
              Text('Already have an account? Login instead!'))

            ],),
      ),

    );
  }

   _register(BuildContext context, [int? index]) async {
    UserManager.username = _usernameController.text;
    UserManager.password = _passwordController.text;


    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', UserManager.username);
    prefs.setString('password', UserManager.password);

    logdata newlogdata= logdata(no: UserManager.username, password: UserManager.password);

    if (!UserManager.userExists(UserManager.username)) {
      UserManager.addUser(newlogdata);
      print('User registered successfully.');
    } else {
      print('User already exists.');
      }


    }

    Future<void> _reg() async{

      UserManager.username = _usernameController.text;

    String email=_usernameController.text+ '@mobile.com';
    String pass= _passwordController.text;

    User? user=await _authService.registerWithEmailAndPassword(email, pass);

    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage(title: 'Your Sensor Configurations')),
      );
      print('Sign up successful: ${user.email}');
      print(pass);
      ScaffoldMessenger.of(context).showSnackBar((SnackBar(content: Text('Registeration successfull!'), duration: Duration(seconds: 1),)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please try again.', style: TextStyle(color: Colors.red),)));

      print('failed');
    }

    }

}





