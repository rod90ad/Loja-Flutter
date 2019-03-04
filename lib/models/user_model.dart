import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';

class UserModel extends Model {

  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUser firebaseUser;
  Map<String, dynamic> userData = Map();
  //Usuario Atual
  bool isLoading = false;

  static UserModel of(BuildContext context) => ScopedModel.of<UserModel>(context);

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _loadCurrentUser();
  }

  void signUp({@required Map<String, dynamic> userData,@required  String pass,@required  VoidCallback onSucess,@required  VoidCallback onFail}){
    isLoading = true;
    notifyListeners();

    _auth.createUserWithEmailAndPassword(email: userData["email"], password: pass).then((user) async {
      firebaseUser = user;

      await _saveUserData(userData);

      onSucess();
      isLoading = false;
      notifyListeners();
    }).catchError((e){
      onFail();
      isLoading = false;
      notifyListeners();
    });
  }

  void signIn({@required String email,@required String password,@required VoidCallback onSucess,@required VoidCallback onFail})async{
    isLoading = true;
    notifyListeners();
    await _auth.signInWithEmailAndPassword(email: email, password: password).then((user) async{
      firebaseUser = user;
      await _loadCurrentUser();
      onSucess();
      isLoading = false;
      notifyListeners();
    }).catchError((e){
      onFail();
      isLoading = false;
      notifyListeners();
    });
  }

  void recoveryPass(String email){
    _auth.sendPasswordResetEmail(email: email);
  }

  void signOut()async{
    await _auth.signOut();

    userData = Map();
    firebaseUser = null;

    notifyListeners();
  }

  bool isLoggedIn(){
    return firebaseUser!=null;
  }

  Future<Null> _saveUserData(Map<String, dynamic> user) async{
    this.userData = user;
    await Firestore.instance.collection("users").document(firebaseUser.uid).setData(userData);
  }

  Future<Null> _loadCurrentUser()async{
    if(firebaseUser==null)
      firebaseUser = await _auth.currentUser();

    if(firebaseUser!=null){
      if(userData["name"] == null){
        DocumentSnapshot documentSnapshot =
            await Firestore.instance.collection("users").document(firebaseUser.uid).get();
        userData = documentSnapshot.data;
      }
    }
    notifyListeners();
  }

}