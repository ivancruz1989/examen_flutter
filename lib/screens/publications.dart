import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      title: json['title'],
      body: json['body'],
    );
  }

  Post copyWith({String? title, String? body}) {
    return Post(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late Future<List<Post>> _futurePosts;
  List<Post>? _posts;

  @override
  void initState() {
    super.initState();
    _futurePosts = fetchPosts();
  }

  Future<List<Post>> fetchPosts() async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts?userId=1'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar publicaciones');
    }
  }

  Future<void> _deletePost(int index) async {
    final post = _posts![index];
    final response = await http.delete(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/${post.id}'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _posts!.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar publicación')),
      );
    }
  }

  Future<void> _showCreatePostDialog() async {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String body = '';
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Crear Publicación'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (value) => title = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contenido'),
                    maxLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (value) => body = value,
                  ),
                ],
              ),
            ),
            actions: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (!loading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              if (!loading)
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() => loading = true);
                      final response = await http.post(
                        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
                        headers: {'Content-Type': 'application/json; charset=UTF-8'},
                        body: json.encode({
                          'userId': 1,
                          'title': title,
                          'body': body,
                        }),
                      );
                      setDialogState(() => loading = false);
                      if (response.statusCode == 201) {
                        final newPost = Post.fromJson(json.decode(response.body));
                        if (mounted) {
                          setState(() {
                            _posts?.insert(0, newPost);
                          });
                          Navigator.pop(context);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al crear publicación')),
                        );
                      }
                    }
                  },
                  child: const Text('Crear'),
                ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showEditPostDialog(int index) async {
    final post = _posts![index];
    final _formKey = GlobalKey<FormState>();
    String title = post.title;
    String body = post.body;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Publicación'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (value) => title = value,
                  ),
                  TextFormField(
                    initialValue: body,
                    decoration: const InputDecoration(labelText: 'Contenido'),
                    maxLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    onChanged: (value) => body = value,
                  ),
                ],
              ),
            ),
            actions: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (!loading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              if (!loading)
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() => loading = true);
                      final response = await http.put(
                        Uri.parse('https://jsonplaceholder.typicode.com/posts/${post.id}'),
                        headers: {'Content-Type': 'application/json; charset=UTF-8'},
                        body: json.encode({
                          'userId': 1,
                          'title': title,
                          'body': body,
                        }),
                      );
                      setDialogState(() => loading = false);
                      if (response.statusCode == 200) {
                        final updatedPost = Post.fromJson(json.decode(response.body));
                        if (mounted) {
                          setState(() {
                            _posts![index] = updatedPost;
                          });
                          Navigator.pop(context);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al editar publicación')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones')),
      body: FutureBuilder<List<Post>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay publicaciones'));
          }
          _posts ??= List<Post>.from(snapshot.data!);

          return ListView.separated(
            itemCount: _posts!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final post = _posts![index];
              return Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => _showEditPostDialog(index), // Editar al tocar
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: const Text('¿Deseas eliminar esta publicación?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deletePost(index);
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
        tooltip: 'Crear Publicación',
      ),
    );
  }
}