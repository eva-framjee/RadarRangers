import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCopyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> copyUserVitalsData({
    required String sourceUserDocId,
    required String targetUserDocId,
  }) async {
    final sourceRef = _firestore.collection('users').doc(sourceUserDocId);
    final targetRef = _firestore.collection('users').doc(targetUserDocId);

    final sourceDoc = await sourceRef.get();
    if (!sourceDoc.exists) {
      throw Exception('Source user document does not exist.');
    }

    final sourceData = sourceDoc.data();
    if (sourceData == null) {
      throw Exception('Source user document has no data.');
    }

    await _copySubcollection(
      sourceRef: sourceRef,
      targetRef: targetRef,
      subcollectionName: 'heart_data',
    );

    await _copySubcollection(
      sourceRef: sourceRef,
      targetRef: targetRef,
      subcollectionName: 'breath_data',
    );
  }

  Future<void> _copySubcollection({
    required DocumentReference<Map<String, dynamic>> sourceRef,
    required DocumentReference<Map<String, dynamic>> targetRef,
    required String subcollectionName,
  }) async {
    final sourceSnapshot = await sourceRef
        .collection(subcollectionName)
        .limit(1)
        .get();
    for (final doc in sourceSnapshot.docs) {
      await targetRef.collection(subcollectionName).doc(doc.id).set(doc.data());
    }
  }
}