import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lecturer_page.dart';
import 'admin_page.dart';
import 'student_page.dart';

TextEditingController _usernameController = TextEditingController();
TextEditingController _passwordController = TextEditingController();

void _Login(BuildContext context) async {
  String studentNumber = _usernameController.text.trim();
  String password = _passwordController.text.trim();

  if (studentNumber.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter both student number and password.')),
    );
    return;
  }

  try {
    String email = '$studentNumber@gmail.com'; 
    
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    
    if (userDoc.exists) {

      var userData = userDoc.data() as Map<String, dynamic>;
      String userType = userData['role'].toString().toLowerCase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful as $userType!')),
      );
      
      if (userType == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentPage()),
        );
      } else if (userType == 'lecturer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LecturerPage()),
        );
      } else if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown user role: $userType')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data not found in database.')),
      );
    }
    
  } on FirebaseAuthException catch (e) {
    String message = 'Login failed';
    if (e.code == 'user-not-found') {
      message = 'No user found with this student number.';
    } else if (e.code == 'wrong-password') {
      message = 'Wrong password provided.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    print('Error details: $e'); // Debug print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    )
  );
}

class HomePage extends StatefulWidget {

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    
return Scaffold(
  body: Stack(

    children: <Widget>[

    Stack(
      children: [

        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        
        Positioned(
          top: 70, 
          left: 0,
          right: 0,
          child: Container(
            height: 170, 
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/uitm.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    
      
Stack(
  children: [
    // Main content with login form
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Stack(
            children: [
              Text("Login Page", style: TextStyle(
                fontSize: 45, 
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 11
                  ..color = Colors.black,
              ),),
              Text("Login Page", style: TextStyle(
                fontSize: 45, 
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(255, 255, 255, 1),
              ),),
            ],
          ),
          SizedBox(height: 15,), 
          Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(
                color: const Color.fromARGB(255, 0, 0, 0), 
                width: 3, 
              ),
              boxShadow: [ 
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(20), 
            child: Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 235, 227, 227), 
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Username",
                      contentPadding: EdgeInsets.all(20),
                    ),
                  ),
                ),
                SizedBox(height: 20), 
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 235, 227, 227),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Password",
                      contentPadding: EdgeInsets.all(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: SizedBox()),
        Center(
          child: GestureDetector(
            onTap: () {
              print('Login tapped');
              _Login(context);
            },
            child: SizedBox(
              width: 150, 
              height: 60, 
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 3,
                  ),
                  color: const Color.fromARGB(255, 0, 249, 25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Login', 
                    style: TextStyle(
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 320), 
      ],
    ),

  ],
),

    ],
  ),
);

  }
}
