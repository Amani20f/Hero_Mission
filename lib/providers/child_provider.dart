import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// ChildProvider — manages the list of children of the signed-in parent.
class ChildProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _children = [];
  UserModel? _selectedChild;
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<UserModel> get children => _children;
  UserModel? get selectedChild => _selectedChild;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Stream ────────────────────────────────────────────────────────────────

  void listenToChildren(String parentId) {
    _isLoading = true;
    notifyListeners();

    // Only this parent's children (never children of other families)
    final stream = _firestoreService.getChildrenByParent(parentId);

    stream.listen(
      (children) {
        _children = children;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void selectChild(UserModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  void clearSelection() {
    _selectedChild = null;
    notifyListeners();
  }

  Future<bool> deleteChild(String childId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.deleteChild(childId);
      if (_selectedChild?.id == childId) {
        _selectedChild = null;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
