import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/reward_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../core/utils/level_utils.dart';

/// FirestoreService — CRUD operations for tasks, rewards, progress, and users
class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// UID of the signed-in parent. Every query is scoped to it so that
  /// Firestore security rules can guarantee a family only sees its own data.
  String get _parentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Collections ───────────────────────────────────────────────────────────

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _tasks => _db.collection('tasks');
  CollectionReference get _rewards => _db.collection('rewards');
  CollectionReference get _progress => _db.collection('progress');
  CollectionReference get _redemptions => _db.collection('redemptions');

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Get all children belonging to a specific parent (real-time stream)
  Stream<List<UserModel>> getChildrenByParent(String parentId) {
    return _users
        .where('parentId', isEqualTo: parentId)
        .where('role', isEqualTo: 'child')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateChildAvatar(String childId, int avatarIndex) async {
    await _users.doc(childId).update({'avatarIndex': avatarIndex});
  }

  Future<void> deleteChild(String childId) async {
    final batch = _db.batch();

    // 1. Delete user
    batch.delete(_users.doc(childId));

    // 2. Delete progress
    batch.delete(_progress.doc(childId));

    // 3. Delete tasks
    final tasksSnap = await _tasks
        .where('parentId', isEqualTo: _parentUid)
        .where('childId', isEqualTo: childId)
        .get();
    for (var doc in tasksSnap.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete rewards
    final rewardsSnap = await _rewards
        .where('parentId', isEqualTo: _parentUid)
        .where('childId', isEqualTo: childId)
        .get();
    for (var doc in rewardsSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Stream<List<TaskModel>> getChildTasksStream(String childId) {
    return _tasks
        .where('parentId', isEqualTo: _parentUid)
        .where('childId', isEqualTo: childId)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<TaskModel>> getPendingApprovalsStream(String parentId) {
    return _tasks
        .where('parentId', isEqualTo: parentId)
        .where('status', isEqualTo: 'completed')
        // .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> createTask({
    required String title,
    String? description,
    required int points,
    required String difficulty,
    required int xp,
    required String childId,
    required String parentId,
    DateTime? deadline,
  }) async {
    final task = TaskModel(
      id: '',
      title: title,
      description: description ?? '',
      points: points,
      difficulty: difficulty,
      xp: xp,
      childId: childId,
      parentId: parentId,
      deadline: deadline,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _tasks.doc().set(task.toMap());
  }

  Future<void> completeTask(String taskId) async {
    await _tasks.doc(taskId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveTask(TaskModel task) async {
    final batch = _db.batch();
    batch.update(_tasks.doc(task.id), {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    final progressRef = _progress.doc(task.childId);
    final progressSnap = await progressRef.get();

    if (progressSnap.exists) {
      final progress = ProgressModel.fromMap(
        progressSnap.data() as Map<String, dynamic>,
        task.childId,
      );

      final newXp = progress.xp + task.xp;
      final newPoints = progress.points + task.points;
      final newLevel = LevelUtils.getLevel(newXp);
      final newStreak = progress.streak + 1;
      final newApprovedCount = progress.approvedTasksCount + 1;

      final newlyEarnedBadges = BadgeModel.checkNewBadges(
        xp: newXp,
        existingBadges: progress.badges,
      );
      final allBadges = List<String>.from(progress.badges)..addAll(newlyEarnedBadges);

      batch.update(progressRef, {
        'points': newPoints,
        'xp': newXp,
        'level': newLevel,
        'streak': newStreak,
        'approvedTasksCount': newApprovedCount,
        'badges': allBadges,
        'lastActivityDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> rejectTask(String taskId) async {
    await _tasks.doc(taskId).update({'status': 'rejected'});
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
  }

  // ── Rewards ───────────────────────────────────────────────────────────────

  Stream<List<RewardModel>> getRewardsStream(String childId) {
    return _rewards
        .where('parentId', isEqualTo: _parentUid)
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                RewardModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> createReward({
    required String title,
    String? description,
    required int cost,
    String iconName = '🎁',
    required String childId,
    required String parentId,
  }) async {
    final reward = RewardModel(
      id: '',
      title: title,
      description: description ?? '',
      cost: cost,
      iconName: iconName,
      childId: childId,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    await _rewards.doc().set(reward.toMap());
  }

  Future<void> deleteReward(String rewardId) async {
    await _rewards.doc(rewardId).delete();
  }

  Future<bool> redeemReward(RewardModel reward, int currentPoints) async {
    if (currentPoints < reward.cost) return false;

    final batch = _db.batch();
    
    // Only deduct points. Do not mark as redeemed so it can be bought again!
    batch.update(_progress.doc(reward.childId), {
      'points': FieldValue.increment(-reward.cost),
    });

    // Log the redemption for parent notifications
    batch.set(_redemptions.doc(), {
      'rewardId': reward.id,
      'rewardTitle': reward.title,
      'cost': reward.cost,
      'childId': reward.childId,
      'parentId': reward.parentId,
      'redeemedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return true;
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  Stream<ProgressModel?> getProgressStream(String childId) {
    return _progress.doc(childId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ProgressModel.fromMap(
        snap.data() as Map<String, dynamic>,
        childId,
      );
    });
  }

  Future<ProgressModel?> getProgress(String childId) async {
    final snap = await _progress.doc(childId).get();
    if (!snap.exists) return null;
    return ProgressModel.fromMap(snap.data() as Map<String, dynamic>, childId);
  }

  // ── Redemptions History ───────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getRedemptionsStream(String childId) {
    return _redemptions
        .where('parentId', isEqualTo: _parentUid)
        .where('childId', isEqualTo: childId)
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  Future<void> resetParentData(String parentId) async {
    final batch = _db.batch();

    // 1. Get all children
    final childrenSnap = await _users
        .where('parentId', isEqualTo: parentId)
        .where('role', isEqualTo: 'child')
        .get();

    for (var doc in childrenSnap.docs) {
      batch.delete(doc.reference);
      // Also delete their progress
      batch.delete(_progress.doc(doc.id));
    }

    // 2. Get all tasks
    final tasksSnap = await _tasks.where('parentId', isEqualTo: parentId).get();
    for (var doc in tasksSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Get all rewards
    final rewardsSnap = await _rewards.where('parentId', isEqualTo: parentId).get();
    for (var doc in rewardsSnap.docs) {
      batch.delete(doc.reference);
    }

    // 4. Get all redemptions
    final redemptionsSnap = await _redemptions.where('parentId', isEqualTo: parentId).get();
    for (var doc in redemptionsSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
