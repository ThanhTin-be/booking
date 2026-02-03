import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Dữ liệu mẫu danh sách người dùng
  final List<Map<String, dynamic>> users = [
    {
      "name": "Thanh Tín",
      "email": "tin@gmail.com",
      "role": "Admin",
      "status": "Hoạt động",
      "avatar": "https://i.pravatar.cc/150?img=12",
    },
    {
      "name": "Anh Thư",
      "email": "thu@gmail.com",
      "role": "User",
      "status": "Hoạt động",
      "avatar": "https://i.pravatar.cc/150?img=5",
    },
    {
      "name": "Minh Nhật",
      "email": "nhat@gmail.com",
      "role": "User",
      "status": "Bị khóa",
      "avatar": "https://i.pravatar.cc/150?img=8",
    },
    {
      "name": "Hoàng Nam",
      "email": "nam@gmail.com",
      "role": "User",
      "status": "Hoạt động",
      "avatar": "https://i.pravatar.cc/150?img=15",
    },
  ];

  void _changeUserRole(int index) {
    String currentRole = users[index]['role'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đổi quyền hạn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("User"),
              value: "User",
              groupValue: currentRole,
              onChanged: (value) {
                setState(() => users[index]['role'] = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text("Admin"),
              value: "Admin",
              groupValue: currentRole,
              onChanged: (value) {
                setState(() => users[index]['role'] = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final bool isLocked = user['status'] == "Bị khóa";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(user['avatar']),
              ),
              title: Row(
                children: [
                  Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: user['role'] == "Admin" ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user['role'],
                      style: TextStyle(
                        color: user['role'] == "Admin" ? Colors.red : Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'], style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    user['status'],
                    style: TextStyle(
                      color: isLocked ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                onSelected: (value) {
                  if (value == 'role') {
                    _changeUserRole(index);
                  } else if (value == 'lock') {
                    setState(() {
                      users[index]['status'] = isLocked ? "Hoạt động" : "Bị khóa";
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Sửa thông tin")),
                  const PopupMenuItem(value: 'role', child: Text("Đổi quyền hạn")),
                  PopupMenuItem(
                    value: 'lock',
                    child: Text(
                      isLocked ? "Mở khóa tài khoản" : "Khóa tài khoản",
                      style: TextStyle(color: isLocked ? Colors.green : Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
