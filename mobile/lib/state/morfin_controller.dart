import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../models/morfin_models.dart';
import '../services/morfin_api.dart';

class MorfinController extends ChangeNotifier {
  static const _tokenKey = 'morfin_jwt_token_v1';

  final MorfinApi api;
  MorfinUser? user;
  DashboardPayload? dashboard;
  bool isInitialized = false;
  bool isLoading = false;
  bool hasPassedSplash = false;
  String? errorMessage;
  String selectedBudgetPeriod = 'daily';
  bool _googleInitialized = false;

  MorfinController({MorfinApi? api}) : api = api ?? MorfinApi();

  bool get isAuthenticated => user != null;

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        api.setToken(token);
        user = await api.fetchMe();
        dashboard = await api.fetchDashboard();
        hasPassedSplash = true;
      }
    } catch (_) {
      api.setToken(null);
      user = null;
    } finally {
      isInitialized = true;
      isLoading = false;
      notifyListeners();
    }
  }

  void completeSplash() {
    hasPassedSplash = true;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _persistSession(AuthResult auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.token);
    api.setToken(auth.token);
    user = auth.user;
    dashboard = await api.fetchDashboard();
    hasPassedSplash = true;
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final auth = await api.register(name: name, email: email, password: password);
      await _persistSession(auth);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final auth = await api.login(email: email, password: password);
      await _persistSession(auth);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (kIsWeb && AppConfig.googleClientId.isEmpty) {
        throw MorfinApiException(
          'Google OAuth Client ID Web belum diatur (--dart-define=GOOGLE_CLIENT_ID=...). Gunakan login Email atau pasang Client ID di Google Cloud Console.',
        );
      }

      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
          serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
        );
        _googleInitialized = true;
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      String? accessToken;
      if (idToken == null || idToken.isEmpty) {
        final authz = await account.authorizationClient.authorizeScopes(['email', 'profile']);
        accessToken = authz.accessToken;
      }

      final auth = await api.loginWithGoogle(idToken: idToken, accessToken: accessToken);
      await _persistSession(auth);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    api.setToken(null);
    user = null;
    dashboard = null;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    if (!isAuthenticated) return;
    try {
      dashboard = await api.fetchDashboard();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleHideBalance() async {
    if (user == null) return;
    final next = !user!.hideBalance;
    user = user!.copyWith(hideBalance: next);
    notifyListeners();
    try {
      user = await api.updatePreferences(hideBalance: next);
      notifyListeners();
    } catch (_) {}
  }

  void setBudgetPeriod(String period) {
    selectedBudgetPeriod = period;
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required String category,
    required String type,
    required int amount,
    required String paymentMethod,
  }) async {
    await api.createTransaction(
      title: title,
      category: category,
      type: type,
      amount: amount,
      paymentMethod: paymentMethod,
    );
    await refreshDashboard();
  }

  Future<void> toggleTxVerified(MorfinTransaction tx) async {
    await api.toggleTransactionVerified(tx.id, !tx.verified);
    await refreshDashboard();
  }

  Future<void> deleteTransaction(String id) async {
    await api.deleteTransaction(id);
    await refreshDashboard();
  }

  Future<void> addBudget({
    required String name,
    required String category,
    required String period,
    required int limitAmount,
  }) async {
    await api.createBudget(
      name: name,
      category: category,
      period: period,
      limitAmount: limitAmount,
    );
    await refreshDashboard();
  }

  Future<void> topUpWallet(MorfinWallet wallet, int delta) async {
    await api.updateWalletBalance(wallet.id, (wallet.currentAmount + delta).clamp(0, 999999999));
    await refreshDashboard();
  }

  Future<void> addGoal({
    required String title,
    required String icon,
    required int targetAmount,
    required int savedAmount,
  }) async {
    await api.createGoal(
      title: title,
      icon: icon,
      targetAmount: targetAmount,
      savedAmount: savedAmount,
    );
    await refreshDashboard();
  }

  Future<void> cycleGoalStatus(MorfinGoal goal) async {
    final next = goal.status == 'completed'
        ? 'active'
        : goal.status == 'active'
            ? 'paused'
            : 'completed';
    await api.updateGoalStatus(goal.id, next);
    await refreshDashboard();
  }
}
