import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loja_virtual/datas/product_data.dart';

class CartProduct{

  String cId;

  String category;
  String pId;

  int quantity;
  String size;

  ProductData productData;

  CartProduct();

  CartProduct.fromDocument(DocumentSnapshot document){
    cId = document.documentID;
    category = document.data["category"];
    pId = document.data["pid"];
    quantity = document.data["quantity"];
    size = document.data["size"];
  }

  Map<String, dynamic> toMap(){
    return {
      "category":category,
      "pid":pId,
      "quantity":quantity,
      "size":size,
      "product": productData.toResumeMap()
    };
  }

}