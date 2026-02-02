import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class BlogListPage extends StatelessWidget {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('Blogs');

  @override
  Widget build(BuildContext context) {
    //?.uid:
    // This uses a null-aware operator (?.) to safely access the uid property of currentUser. If currentUser is null, it will simply set userId to null without throwing an error.
    final userId = FirebaseAuth.instance.currentUser ?.uid;

    // Check if userId is null
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Food Blog',
            style: TextStyle(color: Colors.lightBlue),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Please log in to view your blogs.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Food Blog',
          style: TextStyle(color: Colors.lightBlue),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      //StreamBuilder is a Flutter widget that listens to changes in the Firebase Realtime Database and updates the UI accordingly.
      body: StreamBuilder(
        //onValue stream of the Blogs node for the specific userId.
        stream: _dbRef.child(userId).onValue,
        builder: (context, snapshot) {
          //Shows a loading indicator while the data is being fetched.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          //Displays an error message if there's an issue with the stream.
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          //If no blogs are found, a message is displayed.
          if (snapshot.hasData) {
            final data = snapshot.data!.snapshot.value;

            //If no blogs are found, a message is displayed.
            if (data == null) {
              return Center(child: Text('No Blogs Found'));
            }

            //Ensures the data is treated as a Map (key-value pairs) and converts it to a Dart-friendly format.
            if (data is Map) {
              //converts the raw data retrieved from the Firebase Realtime Database into a Dart-friendly Map<String, dynamic> format. This is necessary because Firebase's snapshot.value often returns data in a generic format (like Object?), and casting it explicitly ensures type safety.
              final blogs = Map<String, dynamic>.from(data);
              return ListView(
                //part of the Flutter ListView widget's children property, where the blogs map is iterated over to create a list of widgets dynamically.
                children: blogs.entries.map((entry) {
                  //extracts the unique key (entry.key) of the current MapEntry in the blogs.entries iteration and assigns it to the blogKey variable.
                  final blogKey = entry.key; // Get the unique key for the blog
                  //converts the entry.value, which is the value of a MapEntry in the blogs.entries iteration, into a Dart Map<String, dynamic>
                  final blog = Map<String, dynamic>.from(entry.value);
                  return BlogPost(
                    //Ensures that even if the title is missing or null, the app has a default value to display, improving user experience and preventing crashes.
                    title: blog['title'] ?? 'No Title',
                    description: blog['description'] ?? 'No Description',
                    image: blog['image'] ?? '',
                    blogKey: blogKey, // Pass the blog key
                    //passing a callback function to the onDelete property of the BlogPost widget.
                    onDelete: () => _deleteBlog(context, userId, blogKey), // Pass the delete function
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditBlogPage(
                            blogKey: blogKey,
                            //The ?? operator provides a fallback value if blog['title'] is null.
                            title: blog['title'] ?? '',
                            description: blog['description'] ?? '',
                            image: blog['image'] ?? '',
                            foodName: blog['food_name'] ?? '',
                            carbs: blog['carbs'] ?? '',
                            carbo: blog['carbo'] ?? '',
                            fats: blog['fats'] ?? '',
                            protein: blog['protein'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            }
            return Center(child: Text('Unexpected data format in database'));
          }

          return Center(child: Text('Error loading blogs'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateBlogPage()),
          );
        },
      ),
    );
  }

  // Method to delete a blog
  void _deleteBlog(BuildContext context, String userId, String blogKey) {
    //Firebase Realtime Database operation in Flutter that performs the deletion of a specific blog post for a particular user.
    _dbRef.child(userId).child(blogKey).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blog deleted successfully')),
      );
    }).catchError((error) {
      print('Failed to delete blog: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete blog')),
      );
    });
  }
}

class BlogPost extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final String blogKey; // Unique key for the blog
  final VoidCallback onDelete; // Callback for delete action
  final VoidCallback onEdit; // Callback for edit action

  BlogPost({
    required this.title,
    required this.description,
    required this.image,
    required this.blogKey,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color : Colors.lightBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image.isNotEmpty)
            Image.memory(
              base64Decode(image),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ListTile(
            title: Text(title, style: TextStyle(color: Colors.white)),
            subtitle: Text(description, style: TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: onEdit, // Call the edit function when pressed
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: onDelete, // Call the delete function when pressed
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditBlogPage extends StatefulWidget {
  final String blogKey;
  final String title;
  final String description;
  final String image;
  final String foodName;
  final String carbs;
  final String carbo;
  final String fats;
  final String protein;

  EditBlogPage({
    required this.blogKey,
    required this.title,
    required this.description,
    required this.image,
    required this.foodName,
    required this.carbs,
    required this.carbo,
    required this.fats,
    required this.protein,
  });

  @override
  _EditBlogPageState createState() => _EditBlogPageState();
}

class _EditBlogPageState extends State<EditBlogPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('Blogs');
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _carboController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();

  String _imageBase64 = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title;
    _descriptionController.text = widget.description;
    _foodNameController.text = widget.foodName;
    _carbsController.text = widget.carbs;
    _carboController.text = widget.carbo;
    _fatsController.text = widget.fats;
    _proteinController.text = widget.protein;
    _imageBase64 = widget.image; // Load existing image
  }

  Future<void> _pickImage() async {
    //Creates an instance of the ImagePicker class from the image_picker package, which allows you to pick images from the gallery or camera.
    final picker = ImagePicker();
    //final pickedFile = await picker.pickImage(source: ImageSource.gallery);: Opens the device's image gallery and lets the user pick an image. It returns a PickedFile object.
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      //final imageBytes = await pickedFile.readAsBytes();: Reads the selected image as a byte array. This is necessary for encoding the image into base64.
      final imageBytes = await pickedFile.readAsBytes();
      //setState(() { _imageBase64 = base64Encode(imageBytes); });: Converts the byte array (imageBytes) into a base64-encoded string using base64Encode. This base64 string is then stored in _imageBase64, which is presumably a class-level variable. setState triggers a rebuild of the widget to reflect any changes.
      setState(() {
        _imageBase64 = base64Encode(imageBytes);
      });
    }
  }

  void _updateBlog(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser ?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to update a blog')),
      );
      return;
    }

    final blogData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'food_name': _foodNameController.text,
      'carbs': _carbsController.text,
      'carbo': _carboController.text,
      'fats': _fatsController.text,
      'protein': _proteinController.text,
      'image': _imageBase64,
      'uid': userId,
    };

    _dbRef.child(userId).child(widget.blogKey).update(blogData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blog updated successfully')),
      );
      Navigator.pop(context);
    }).catchError((error) {
      print('Failed to update blog: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update blog')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Blog',
          style: TextStyle(color: Colors.lightBlue),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.upload, color: Colors.white),
              label: Text('Upload Image', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
            if (_imageBase64.isNotEmpty)
              Image.memory(
                base64Decode(_imageBase64),
                height: 150,
              ),
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
            TextField(controller: _foodNameController, decoration: InputDecoration(labelText: 'Food Name')),
            TextField(controller: _carbsController, decoration: InputDecoration(labelText: 'Carbs')),
            TextField(controller: _carboController, decoration: InputDecoration(labelText: 'Carbo')),
            TextField(controller: _fatsController, decoration: InputDecoration(labelText: 'Fats')),
            TextField(controller: _proteinController, decoration: InputDecoration(labelText: 'Protein')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _updateBlog(context),
              child: Text('Update', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateBlogPage extends StatefulWidget {
  @override
  _CreateBlogPageState createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('Blogs');
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _carboController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();

  String _imageBase64 = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(imageBytes);
      });
    }
  }

  void _submitBlog(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser ?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to create a blog')),
      );
      return;
    }

    final blogData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'food_name': _foodNameController.text,
      'carbs': _carbsController.text,
      'carbo': _carboController.text,
      'fats': _fatsController.text,
      'protein': _proteinController.text,
      'image': _imageBase64,
      'uid': userId,
    };

    _dbRef.child(userId).push().set(blogData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blog created successfully')),
      );
      Navigator.pop(context);
    }).catchError((error) {
      print('Failed to add blog: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create blog')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Create Blog',
          style: TextStyle(color: Colors.lightBlue),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              icon: Icon(Icons.upload, color: Colors.white),
              label: Text('Upload Image', style: TextStyle(color: Colors.white)),
            ),
            if (_imageBase64.isNotEmpty)
              Image.memory(
                base64Decode(_imageBase64),
                height: 150,
              ),
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
            TextField(controller: _foodNameController, decoration: InputDecoration(labelText: 'Food Name')),
            TextField(controller: _carbsController, decoration: InputDecoration(labelText: 'Carbs')),
            TextField(controller: _carboController, decoration: InputDecoration(labelText: 'Carbo')),
            TextField(controller: _fatsController, decoration: InputDecoration(labelText: 'Fats')),
            TextField(controller: _proteinController, decoration: InputDecoration(labelText: 'Protein')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _submitBlog(context),
              child: Text('Post', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),
          ],
        ),
      ),
    );
  }
}