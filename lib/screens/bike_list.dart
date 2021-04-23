import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bike.dart';
import '../screens/bike_view.dart';
import '../widgets/navdrawer.dart';
import '../screens/sign_in.dart';

// import '../screens/single_bike_map.dart';

class BikeList extends StatefulWidget {
  static const routeName = 'bikeList';
  @override
  _BikeListState createState() => _BikeListState();
}

class _BikeListState extends State<BikeList> {
  final bikes = List<Map>.generate(1000, (i) {
    return {'name': 'Bike $i', 'description': 'Bike text $i'};
  });

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User>();
    if (firebaseUser != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Bike Kollective')),
        body: bikeList(),
        drawer: navDrawer(context),
      );
    } else {
      return SignIn();
    }
  }

  StreamBuilder bikeList() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('bikes')
            .orderBy('rating', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data.docs != null &&
              snapshot.data.docs.length > 0) {
            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.docs[index]),
            );
          } else {
            print(snapshot);
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    final thisBike = Bike.fromMap(document.data());
    return Semantics(
        button: true,
        onTapHint: 'view bike',
        child: ListTile(
          leading: Image.network(thisBike.url,  height: 50,width: 70,fit: BoxFit.fill),
          title: Text('Bike ${thisBike.bikeName}'),
          subtitle: Text('${thisBike.bikeDescription}'),
          onTap: () {
            Navigator.of(context)
                .pushNamed(BikeView.routeName, arguments: thisBike);
          },
        ));
  }
}
