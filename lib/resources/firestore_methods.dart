import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage,
  ) async {
    String res = 'Some error occured';
    String postId = const Uuid().v1();
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
      );

      _firestore.collection('posts').doc(postId).set(
            post.toJson(),
          );
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> likePost(String postId, String uid, List likes) async {
    String res = 'Some error occured';
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      res = 'success';
    } catch (e) {
      print(e.toString());
    }
    return res;
  }

  Future<String> postComment(String postId, String text, String uid,
      String name, String profilePic) async {
    String res = 'Some error occured';
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        print('Text is empty');
        res = 'Please enter text';
      }
    } catch (e) {
      print(e.toString());
    }
    return res;
  }

  //Deleting the post
  Future<void> deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      print('Deleted selected post');
    } catch (e) {
      print(e.toString());
    }
  }

  //Follow-Following
  Future<void> followUser(String uid, String followId) async {
    DocumentSnapshot snap =
        await FirebaseFirestore.instance.collection('user').doc(uid).get();
    List following = (snap.data()! as dynamic)['following'];

    if (following.contains(followId)) {
      await FirebaseFirestore.instance.collection('user').doc(followId).update({
        "followers": FieldValue.arrayRemove([uid]),
      });
      await FirebaseFirestore.instance.collection('user').doc(uid).update({
        "following": FieldValue.arrayRemove([followId]),
      });
    } else {
      await FirebaseFirestore.instance.collection('user').doc(followId).update({
        "followers": FieldValue.arrayUnion([uid]),
      });
      await FirebaseFirestore.instance.collection('user').doc(uid).update({
        "following": FieldValue.arrayUnion([followId]),
      });
    }
  }
}
