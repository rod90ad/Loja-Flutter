import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loja_virtual/datas/cart_product.dart';
import 'package:loja_virtual/models/user_model.dart';
import 'package:scoped_model/scoped_model.dart';

class CartModel extends Model{

  bool isLoading = false;
  UserModel user;
  String cupomCode;
  int discountPercentage = 0;

  List<CartProduct> products = [];

  CartModel(this.user){
    if(user.isLoggedIn()){
      _loadCartItems();
    }
  }

  static CartModel of(BuildContext context) => ScopedModel.of<CartModel>(context);

  void addCartItem(CartProduct product){
    products.add(product);

    Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart").add(product.toMap())
    .then((doc){
      product.cId = doc.documentID;
    });

    notifyListeners();
  }

  void updatePrices(){
    notifyListeners();
  }

  Future<String> finishOrder()async{
    if(products.length == 0) return null;

    isLoading = true;
    notifyListeners();

    double productsPrice = getProductsPrice();
    double discount = getDiscount();
    double shipPrice = getShipPrice();

    DocumentReference docRef = await Firestore.instance.collection("orders").add({
      "clientid":user.firebaseUser.uid,
      "products":products.map((cartProduct)=> cartProduct.toMap()).toList(),
      "shipprice":shipPrice,
      "productsprice":productsPrice,
      "discount":discount,
      "totalprice":(productsPrice+shipPrice-discount),
      "status":1
    });

    await Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("orders").document(docRef.documentID).setData({
      "id":docRef.documentID
    });

    QuerySnapshot query = await Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart").getDocuments();
    for(DocumentSnapshot doc in query.documents){
      doc.reference.delete();
    }

    products.clear();
    discountPercentage = 0;
    cupomCode = null;

    isLoading = false;
    notifyListeners();

    return docRef.documentID;
  }

  double getProductsPrice(){
    double price = 0.0;
    for(CartProduct c in products){
      if(c.productData != null){
        price += c.productData.price * c.quantity;
      }
    }
    return price;
  }

  double getDiscount(){
    return getProductsPrice() * (discountPercentage/100);
  }

  double getShipPrice(){
    return 9.99;
  }

  void setCupom(String cupomCode, int discountPercentage){
    this.cupomCode = cupomCode;
    this.discountPercentage = discountPercentage;
  }

  void removeCartItem(CartProduct product){
    Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart").document(product.cId).delete();
    products.remove(product);
    notifyListeners();
  }

  void decProduct(CartProduct product){
    product.quantity--;
    Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart")
      .document(product.cId).updateData(product.toMap());
    notifyListeners();
  }

  void incProduct(CartProduct product){
    product.quantity++;
    Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart")
        .document(product.cId).updateData(product.toMap());
    notifyListeners();
  }

  void _loadCartItems()async{
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart").getDocuments();

    products = querySnapshot.documents.map((doc)=> CartProduct.fromDocument(doc)).toList();
    notifyListeners();
  }
}