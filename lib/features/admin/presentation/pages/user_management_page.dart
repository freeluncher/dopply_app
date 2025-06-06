import 'package:flutter/material.dart';
import 'package:dopply_app/features/admin/data/services/account_api_service_admin.dart';
import 'package:dopply_app/features/admin/presentation/pages/user_management_page.dart';

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: ListView(
        children: [
          ListTile(
            title: Text('User Management'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserManagementPage()),
              );
            },
          ),
          // ...other menu options...
        ],
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final AccountApiServiceAdmin _apiService = AccountApiServiceAdmin();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    // Call the getUsers method from AccountApiServiceAdmin
    final users = await _apiService.getUsers() as List<Map<String, dynamic>>;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController emailController = TextEditingController();
        return AlertDialog(
          title: Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                final email = emailController.text;
                if (name.isNotEmpty && email.isNotEmpty) {
                  await _apiService.createUser({'name': name, 'email': email});
                  _fetchUsers();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(
          text: user['name'],
        );
        final TextEditingController emailController = TextEditingController(
          text: user['email'],
        );
        return AlertDialog(
          title: Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                final email = emailController.text;
                if (name.isNotEmpty && email.isNotEmpty) {
                  await _apiService.updateUser(user['id'], {
                    'name': name,
                    'email': email,
                  });
                  _fetchUsers();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    final success = await _apiService.deleteUser(userId);
    if (success) {
      _fetchUsers();
    } else {
      // Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _showAddUserDialog),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    title: Text(user['name'] ?? 'No Name'),
                    subtitle: Text(user['email'] ?? 'No Email'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEditUserDialog(user),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteUser(user['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
