import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

// ignore: must_be_immutable
class Highscore extends StatelessWidget {
  Highscore({super.key, required this.docID});
  String docID;

  @override
  Widget build(BuildContext context) {
    CollectionReference tops = FirebaseFirestore.instance.collection('tops');
    return FutureBuilder(
      future: tops.doc(docID).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          return Text(data['name'] + ' ' + data['score'].toString());
        }
        return Text('Loading...');
      },
    );
  }
}
