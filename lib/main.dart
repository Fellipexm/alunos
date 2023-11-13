import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Notas',
      home: SubjectList(),
    );
  }
}

class Subject {
  String name;

  Subject(this.name);
}

class Student {
  String name;
  Map<String, List<double>> subjectGrades = {};

  Student(this.name);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subjectGrades': subjectGrades,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    final student = Student(json['name']);
    final subjectGradesJson = json['subjectGrades'] as Map<String, dynamic>;
    student.subjectGrades = Map<String, List<double>>.from(subjectGradesJson);
    return student;
  }
}

class DataStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/students.json');
  }

  Future<void> saveData(List<Student> students) async {
    final file = await _localFile;
    final jsonData = students.map((student) => student.toJson()).toList();
    final jsonString = jsonEncode(jsonData);
    await file.writeAsString(jsonString);
  }

  Future<List<Student>?> loadData() async {
    try {
      final file = await _localFile;
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as List<dynamic>;
      final students = jsonData.map((json) => Student.fromJson(json)).toList();
      return students;
    } catch (e) {
      return null;
    }
  }
}

class SubjectList extends StatelessWidget {
  final List<Subject> subjects = [
    Subject('Língua Portuguesa'),
    Subject('Matemática Avançada'),
    // Adicione outras matérias aqui
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Matérias do 3º Ano'),
      ),
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(subjects[index].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentList(subjects[index].name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentList extends StatefulWidget {
  final String subjectName;

  StudentList(this.subjectName);

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  List<Student> students = [];
  TextEditingController nameController = TextEditingController();

  final dataStorage = DataStorage();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final loadedStudents = await dataStorage.loadData();
    if (loadedStudents != null) {
      setState(() {
        students = loadedStudents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alunos de ${widget.subjectName}'),
      ),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return ListTile(
            title: Text(student.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetail(student),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Aluno para ${widget.subjectName}'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Nome do Aluno'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Adicionar'),
              onPressed: () {
                setState(() {
                  students.add(Student(nameController.text));
                });
                Navigator.of(context).pop(); // Feche o diálogo
                _saveData(); // Salve os dados
              },
            ),
          ],
        );
      },
    );
  }

  void _saveData() {
    dataStorage.saveData(students);
  }

  @override
  void dispose() {
    _saveData();
    super.dispose();
  }
}

class StudentDetail extends StatefulWidget {
  final Student student;

  StudentDetail(this.student);

  @override
  _StudentDetailState createState() => _StudentDetailState();
}

class _StudentDetailState extends State<StudentDetail> {
  List<TextEditingController> gradeControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeGradeControllers();
  }

  void _initializeGradeControllers() {
    for (final subject in widget.student.subjectGrades.keys) {
      final grades = widget.student.subjectGrades[subject]!;
      for (var i = 0; i < grades.length; i++) {
        gradeControllers.add(TextEditingController(text: grades[i].toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
      ),
      body: ListView.builder(
        itemCount: widget.student.subjectGrades.length,
        itemBuilder: (context, index) {
          final subject = widget.student.subjectGrades.keys.elementAt(index);
          return Column(
            children: [
              ListTile(
                title: Text(subject),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.student.subjectGrades[subject]!.length,
                itemBuilder: (context, gradeIndex) {
                  return ListTile(
                    title: Text('Bimestre ${gradeIndex + 1}'),
                    subtitle: TextField(
                      controller: gradeControllers[index],
                      decoration: InputDecoration(labelText: 'Nota Bimestre ${gradeIndex + 1}'),
                      keyboardType: TextInputType.number,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveGrades();
        },
        child: Icon(Icons.save),
      ),
    );
  }

  void _saveGrades() {
    for (final subject in widget.student.subjectGrades.keys) {
      final grades = <double>[];
      for (var i = 0; i < widget.student.subjectGrades[subject]!.length; i++) {
        final gradeIndex = indexForSubjectAndBimester(subject, i);
        final grade = double.tryParse(gradeControllers[gradeIndex].text) ?? 0.0;
        grades.add(grade);
      }
      widget.student.subjectGrades[subject] = grades;
    }
    _showResult();
  }

  int indexForSubjectAndBimester(String subject, int bimester) {
    int index = 0;
    for (final subjectName in widget.student.subjectGrades.keys) {
      if (subjectName == subject) {
        return index + bimester;
      }
      index += widget.student.subjectGrades[subjectName]!.length;
    }
    return -1;
  }

  void _showResult() {
    final sum = _calculateAverage(widget.student);
    final result = sum >= 60 ? 'Aprovado' : 'Reprovado';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultado'),
          content: Text('Situação: $result\nMédia: ${(sum).toStringAsFixed(2)}'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateAverage(Student student) {
    double totalSum = 0.0;
    int totalGrades = 0;

    for (final subjectGrades in student.subjectGrades.values) {
      for (final grade in subjectGrades) {
        totalSum += grade;
        totalGrades++;
      }
    }

    if (totalGrades > 0) {
      return totalSum / totalGrades;
    } else {
      return 0.0;
    }
  }

  @override
  void dispose() {
    for (final controller in gradeControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

