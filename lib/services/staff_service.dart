import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffService {
  StaffService._();

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> activeStaff() {
    return firestore
        .collection('staff')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  static Future<void> createStaff({
    required String uid,
    required String name,
    required int age,
    required String occupation,
    required String email,
    required String profileImageUrl,
  }) async {
    final staffReference = firestore.collection('staff').doc(uid);
    final userReference = firestore.collection('users').doc(uid);

    await firestore.runTransaction((transaction) async {
      final staffSnapshot = await transaction.get(staffReference);
      final createdData = <String, dynamic>{
        if (!staffSnapshot.exists) ...{
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser!.uid,
        },
      };

      transaction.set(staffReference, {
        ...createdData,
        'uid': uid,
        'name': name,
        'email': email,
        'age': age,
        'occupation': occupation,
        'profileImageUrl': profileImageUrl,
        'role': 'staff',
        'status': 'active',
      }, SetOptions(merge: true));

      transaction.set(userReference, {
        'role': 'staff',
        'status': 'active',
        'email': email,
        'name': name,
      }, SetOptions(merge: true));
    });
  }

  static Future<void> deactivateStaff(String uid) async {
    final batch = firestore.batch();
    batch.update(firestore.collection('staff').doc(uid), {'status': 'inactive'});
    batch.set(
      firestore.collection('users').doc(uid),
      {'status': 'inactive'},
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
