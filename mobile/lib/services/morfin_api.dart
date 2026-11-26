import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../models/morfin_models.dart';

class MorfinApiException implements Exception {
  final String message;
  final int statusCode;
  MorfinApiException(this.message, [this.statusCode = 0]);
  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final MorfinUser user;
  const AuthResult({required this.token, required this.user});
}

class MorfinApi {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  MorfinApi({String? baseUrl, http.Client? client})
      : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool auth = true}) => {
        'Content-Type': 'application/json',
        if (auth && _token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = {'error': 'Respons server tidak valid (${res.statusCode}).'};
    }
    if (res.statusCode >= 400) {
      throw MorfinApiException(data['error']?.toString() ?? 'Permintaan gagal.', res.statusCode);
    }
    return data;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers(auth: false),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = _decode(res);
    return AuthResult(
      token: data['token'].toString(),
      user: MorfinUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    return AuthResult(
      token: data['token'].toString(),
      user: MorfinUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<AuthResult> loginWithGoogle({String? idToken, String? accessToken}) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: _headers(auth: false),
      body: jsonEncode({
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        if (accessToken != null && accessToken.isNotEmpty) 'accessToken': accessToken,
      }),
    );
    final data = _decode(res);
    return AuthResult(
      token: data['token'].toString(),
      user: MorfinUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<MorfinUser> fetchMe() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/auth/me'), headers: _headers());
    final data = _decode(res);
    return MorfinUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<MorfinUser> updatePreferences({bool? hideBalance, String? name}) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/auth/preferences'),
      headers: _headers(),
      body: jsonEncode({
        'hideBalance': ?hideBalance,
        'name': ?name,
      }),
    );
    final data = _decode(res);
    return MorfinUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<DashboardPayload> fetchDashboard() async {
    final res = await _client.get(Uri.parse('$baseUrl/api/dashboard'), headers: _headers());
    return DashboardPayload.fromJson(_decode(res));
  }

  Future<void> resetAccountData() async {
    final res = await _client.post(Uri.parse('$baseUrl/api/account/reset'), headers: _headers());
    _decode(res);
  }

  Future<void> createTransaction({
    required String title,
    required String category,
    required String type,
    required int amount,
    required String paymentMethod,
    String? walletId,
    DateTime? occurredAt,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/transactions'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'category': category,
        'type': type,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'walletId': ?walletId,
        if (occurredAt != null) 'occurredAt': occurredAt.toUtc().toIso8601String(),
      }),
    );
    _decode(res);
  }

  Future<void> updateTransaction(
    String id, {
    String? title,
    String? category,
    String? type,
    int? amount,
    String? paymentMethod,
    bool? verified,
  }) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/transactions/$id'),
      headers: _headers(),
      body: jsonEncode({
        'title': ?title,
        'category': ?category,
        'type': ?type,
        'amount': ?amount,
        'paymentMethod': ?paymentMethod,
        'verified': ?verified,
      }),
    );
    _decode(res);
  }

  Future<void> toggleTransactionVerified(String id, bool verified) async {
    await updateTransaction(id, verified: verified);
  }

  Future<void> deleteTransaction(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/api/transactions/$id'), headers: _headers());
    _decode(res);
  }

  Future<void> createBudget({
    required String name,
    required String category,
    required String period,
    required int limitAmount,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/budgets'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'category': category,
        'period': period,
        'limitAmount': limitAmount,
      }),
    );
    _decode(res);
  }

  Future<void> updateBudget(
    String id, {
    String? name,
    String? category,
    String? period,
    int? limitAmount,
    int? spentAmount,
  }) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/budgets/$id'),
      headers: _headers(),
      body: jsonEncode({
        'name': ?name,
        'category': ?category,
        'period': ?period,
        'limitAmount': ?limitAmount,
        'spentAmount': ?spentAmount,
      }),
    );
    _decode(res);
  }

  Future<void> deleteBudget(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/api/budgets/$id'), headers: _headers());
    _decode(res);
  }

  Future<void> createWallet({
    required String name,
    required String icon,
    required String colorVariant,
    required int currentAmount,
    required int targetAmount,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/wallets'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'icon': icon,
        'colorVariant': colorVariant,
        'currentAmount': currentAmount,
        'targetAmount': targetAmount,
      }),
    );
    _decode(res);
  }

  Future<void> updateWalletBalance(String id, int currentAmount, {int? targetAmount, String? name}) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/wallets/$id'),
      headers: _headers(),
      body: jsonEncode({
        'currentAmount': currentAmount,
        'targetAmount': ?targetAmount,
        'name': ?name,
      }),
    );
    _decode(res);
  }

  Future<void> deleteWallet(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/api/wallets/$id'), headers: _headers());
    _decode(res);
  }

  Future<void> createGoal({
    required String title,
    required String icon,
    required int targetAmount,
    required int savedAmount,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/goals'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'icon': icon,
        'status': savedAmount >= targetAmount && targetAmount > 0 ? 'completed' : 'active',
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
      }),
    );
    _decode(res);
  }

  Future<void> updateGoal(
    String id, {
    String? title,
    String? status,
    int? savedAmount,
    int? targetAmount,
  }) async {
    final res = await _client.patch(
      Uri.parse('$baseUrl/api/goals/$id'),
      headers: _headers(),
      body: jsonEncode({
        'title': ?title,
        'status': ?status,
        'savedAmount': ?savedAmount,
        'targetAmount': ?targetAmount,
      }),
    );
    _decode(res);
  }

  Future<void> updateGoalStatus(String id, String status) async {
    await updateGoal(id, status: status);
  }

  Future<void> deleteGoal(String id) async {
    final res = await _client.delete(Uri.parse('$baseUrl/api/goals/$id'), headers: _headers());
    _decode(res);
  }

  Future<MorfinChatResult> parseChatText(String text) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/chat/parse'),
      headers: _headers(),
      body: jsonEncode({'text': text}),
    );
    return MorfinChatResult.fromJson(_decode(res));
  }

  Future<MorfinChatResult> scanReceiptImage({
    required String imageBase64,
    String mimeType = 'image/jpeg',
    String? fileName,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/api/chat/scan-receipt'),
      headers: _headers(),
      body: jsonEncode({
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'fileName': ?fileName,
      }),
    );
    return MorfinChatResult.fromJson(_decode(res));
  }
}
