import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: BioPage(),
    );
  }
}

class BioPage extends StatefulWidget {
  @override
  _BioPageState createState() => _BioPageState();
}

class _BioPageState extends State<BioPage> {
  late Future<Map<String, dynamic>> _userData;
  late Future<List<dynamic>> _repositories;
  TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _filteredRepositories;

  @override
  void initState() {
    super.initState();
    _userData = fetchGithubUser();
    _repositories = fetchGithubRepositories();
    _filteredRepositories = _repositories; // Initialize with _repositories
  }

  Future<Map<String, dynamic>> fetchGithubUser() async {
    final response = await http.get(Uri.parse('https://api.github.com/users/PrakharDoneria'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<List<dynamic>> fetchGithubRepositories() async {
    List<dynamic> repositories = [];
    int page = 1;
    bool hasMorePages = true;

    while (hasMorePages) {
      final response = await http.get(Uri.parse('https://api.github.com/users/PrakharDoneria/repos?page=$page&per_page=100'));
      if (response.statusCode == 200) {
        List<dynamic> repos = json.decode(response.body);
        if (repos.isEmpty) {
          hasMorePages = false;
        } else {
          repositories.addAll(repos);
          page++;
        }
      } else {
        throw Exception('Failed to load repositories');
      }
    }

    // Sorting repositories by updated_at date (latest to oldest)
    repositories.sort((a, b) => DateTime.parse(b['updated_at']).compareTo(DateTime.parse(a['updated_at'])));
    
    return repositories;
  }

  void _searchRepositories() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredRepositories = _repositories.then((repositories) {
        return repositories.where((repo) {
          final name = repo['name'].toLowerCase();
          return name.contains(searchTerm);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Who me?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([_userData, _filteredRepositories]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final userData = snapshot.data![0];
            final repositories = snapshot.data![1];
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userData['avatar_url']),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      userData['name'],
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'About Me',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'I am a passionate software developer with expertise in Android app development. Started coding at the age of 11, I am continuously enhancing my skills. Currently learning Python and Java.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'GitHub Repositories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search repositories',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _searchRepositories,
                        child: Text('Search'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: repositories.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            repositories[index]['name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            repositories[index]['description'] ?? 'No description available',
                            style: TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            launch(repositories[index]['html_url']);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
