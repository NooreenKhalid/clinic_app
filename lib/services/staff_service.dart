import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StaffService {
  StaffService._();

  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> activeStaff() {
    return firestore
        .collection('staff')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  static Future<void> createStaff({
    required String name,
    required int age,
    required String occupation,
    required String email,
    required String password,
    required String profileImageUrl,
  }) async {
    await _functions.httpsCallable('createStaffMember').call(<String, dynamic>{
      'name': name,
      'age': age,
      'occupation': occupation,
      'email': email,
      'password': password,
      'profileImageUrl': profileImageUrl,
    });
  }

  static Future<void> deactivateStaff(String uid) async {
    await _functions
        .httpsCallable('deactivateStaffMember')
        .call(<String, dynamic>{'uid': uid});
  }
}
