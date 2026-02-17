import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

// --- 0. KOTAK SIMPANAN DATA (GLOBAL) ---
// Ini tempat kita simpan markah supaya boleh dikongsi antara page
class DataPelajar {
  static double test = 0.0;       // Max 20
  static double assignment = 0.0; // Max 10
  static double project = 0.0;    // Max 20

  // Fungsi untuk kira total carry mark (Max 50)
  static double kiraTotal() {
    return test + assignment + project;
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ICT602 Assignment',
    theme: ThemeData(primarySwatch: Colors.indigo),
    home: LoginPage(),
  ));
}

// --- 1. HALAMAN LOGIN ---
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();

  void _login() {
    String username = _usernameController.text.toLowerCase().trim();

    if (username == 'admin') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPage()));
    } else if (username == 'lecturer') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LecturerPage()));
    } else if (username == 'student') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sila masukkan: admin, lecturer, atau student")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sistem ICT602")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://cdn-icons-png.flaticon.com/512/2995/2995620.png', height: 100), // Ikon hiasan
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "admin / lecturer / student",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                child: Text("LOG MASUK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. HALAMAN ADMIN ---
class AdminPage extends StatelessWidget {
  void _launchURL() async {
    const url = 'https://github.com/addff/2510-ICT602';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel"), backgroundColor: Colors.redAccent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text("Selamat Datang, Administrator", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _launchURL,
              icon: Icon(Icons.web),
              label: Text("Buka Sistem Web"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. HALAMAN LECTURER (KINI BERFUNGSI!) ---
class LecturerPage extends StatefulWidget {
  @override
  _LecturerPageState createState() => _LecturerPageState();
}

class _LecturerPageState extends State<LecturerPage> {
  // Controller untuk pegang text yang ditaip
  final TextEditingController _testCtrl = TextEditingController();
  final TextEditingController _assignCtrl = TextEditingController();
  final TextEditingController _projectCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bila page buka, kita paparkan data semasa (kalau dah ada)
    _testCtrl.text = DataPelajar.test.toString();
    _assignCtrl.text = DataPelajar.assignment.toString();
    _projectCtrl.text = DataPelajar.project.toString();
  }

  void _simpanMarkah() {
    setState(() {
      // Ambil text dari kotak, tukar jadi nombor, dan simpan dalam DataPelajar
      DataPelajar.test = double.tryParse(_testCtrl.text) ?? 0.0;
      DataPelajar.assignment = double.tryParse(_assignCtrl.text) ?? 0.0;
      DataPelajar.project = double.tryParse(_projectCtrl.text) ?? 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Berjaya! Total Carry Mark Pelajar: ${DataPelajar.kiraTotal()}/50"),
        backgroundColor: Colors.green,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kemas Kini Markah"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Masukkan markah pelajar:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _testCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Ujian / Test (Max 20%)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _assignCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Assignment (Max 10%)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _projectCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Projek (Max 20%)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _simpanMarkah,
              icon: Icon(Icons.save),
              label: Text("SIMPAN KE DATABASE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 50)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. HALAMAN STUDENT (DATA REAL-TIME) ---
class StudentPage extends StatefulWidget {
  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  // Ambil total markah terkini dari 'DataPelajar'
  double carryMark = DataPelajar.kiraTotal();
  String selectedGrade = 'A';
  double finalRequired = 0;

  final Map<String, int> gradeThresholds = {
    'A+': 90, 'A': 80, 'A-': 75, 'B+': 70, 'B': 65, 'B-': 60, 'C+': 55, 'C': 50,
  };

  @override
  void initState() {
    super.initState();
    calculate(); // Kira terus bila page buka
  }

  void calculate() {
    setState(() {
      int target = gradeThresholds[selectedGrade]!;
      finalRequired = target - carryMark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard Pelajar"), backgroundColor: Colors.green),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kad Markah
            Card(
              color: Colors.green[50],
              child: ListTile(
                title: Text("Jumlah Carry Mark (50%)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Test: ${DataPelajar.test} | Assign: ${DataPelajar.assignment} | Project: ${DataPelajar.project}"),
                trailing: Text(
                  "${carryMark.toStringAsFixed(1)}",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text("Sasaran Gred Akhir:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedGrade,
              items: gradeThresholds.keys.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text("Gred $value (Min: ${gradeThresholds[value]})"));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedGrade = newValue!;
                  calculate();
                });
              },
            ),
            SizedBox(height: 20),
            
            // Kotak Keputusan
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: finalRequired > 50 ? Colors.red[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                children: [
                  Text("Untuk dapat $selectedGrade, anda perlukan:", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                     finalRequired > 50
                        ? "MUSTAHIL"
                        : finalRequired <= 0
                            ? "Dah Lulus!"
                            : "${finalRequired.toStringAsFixed(1)} / 50",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, 
                      color: finalRequired > 50 ? Colors.red : Colors.blue[900]),
                  ),
                  Text(
                    finalRequired > 50 
                      ? "(Carry mark tak cukup tinggi)" 
                      : finalRequired <= 0 
                        ? "(Carry mark awak dah power!)"
                        : "dalam Final Exam.",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}