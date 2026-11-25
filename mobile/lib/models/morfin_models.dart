class MorfinUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String authProvider;
  final bool hideBalance;
  final String currency;

  const MorfinUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.authProvider,
    required this.hideBalance,
    required this.currency,
  });

  factory MorfinUser.fromJson(Map<String, dynamic> j) => MorfinUser(
        id: j['id']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Pengguna',
        avatarUrl: j['avatarUrl']?.toString(),
        authProvider: j['authProvider']?.toString() ?? 'email',
        hideBalance: j['hideBalance'] == true,
        currency: j['currency']?.toString() ?? 'IDR',
      );

  MorfinUser copyWith({bool? hideBalance, String? name}) => MorfinUser(
        id: id,
        email: email,
        name: name ?? this.name,
        avatarUrl: avatarUrl,
        authProvider: authProvider,
        hideBalance: hideBalance ?? this.hideBalance,
        currency: currency,
      );
}

class MorfinTransaction {
  final String id;
  final String? walletId;
  final String title;
  final String category;
  final String type; // 'income' | 'expense'
  final int amount;
  final String paymentMethod;
  final bool verified;
  final DateTime occurredAt;

  const MorfinTransaction({
    required this.id,
    this.walletId,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    required this.verified,
    required this.occurredAt,
  });

  bool get isIncome => type == 'income';

  factory MorfinTransaction.fromJson(Map<String, dynamic> j) => MorfinTransaction(
        id: j['id']?.toString() ?? '',
        walletId: j['walletId']?.toString(),
        title: j['title']?.toString() ?? '',
        category: j['category']?.toString() ?? 'Lainnya',
        type: j['type']?.toString() ?? 'expense',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        paymentMethod: j['paymentMethod']?.toString() ?? 'QRIS',
        verified: j['verified'] == true,
        occurredAt: DateTime.tryParse(j['occurredAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );
}

class MorfinBudget {
  final String id;
  final String name;
  final String category;
  final String period; // daily | weekly | monthly | yearly
  final int limitAmount;
  final int spentAmount;

  const MorfinBudget({
    required this.id,
    required this.name,
    required this.category,
    required this.period,
    required this.limitAmount,
    required this.spentAmount,
  });

  int get usedPercent => limitAmount > 0 ? ((spentAmount / limitAmount) * 100).clamp(0, 100).round() : 0;

  factory MorfinBudget.fromJson(Map<String, dynamic> j) => MorfinBudget(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        category: j['category']?.toString() ?? 'Lainnya',
        period: j['period']?.toString() ?? 'monthly',
        limitAmount: (j['limitAmount'] as num?)?.toInt() ?? 0,
        spentAmount: (j['spentAmount'] as num?)?.toInt() ?? 0,
      );
}

class MorfinWallet {
  final String id;
  final String name;
  final String icon;
  final String colorVariant;
  final int currentAmount;
  final int targetAmount;
  final int progressPercent;

  const MorfinWallet({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorVariant,
    required this.currentAmount,
    required this.targetAmount,
    required this.progressPercent,
  });

  factory MorfinWallet.fromJson(Map<String, dynamic> j) => MorfinWallet(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'shield',
        colorVariant: j['colorVariant']?.toString() ?? 'lime',
        currentAmount: (j['currentAmount'] as num?)?.toInt() ?? 0,
        targetAmount: (j['targetAmount'] as num?)?.toInt() ?? 0,
        progressPercent: (j['progressPercent'] as num?)?.toInt() ?? 0,
      );
}

class MorfinGoal {
  final String id;
  final String title;
  final String icon;
  final String status; // completed | active | paused
  final int targetAmount;
  final int savedAmount;
  final int progressPercent;

  const MorfinGoal({
    required this.id,
    required this.title,
    required this.icon,
    required this.status,
    required this.targetAmount,
    required this.savedAmount,
    required this.progressPercent,
  });

  bool get isUnlocked => status == 'completed';

  factory MorfinGoal.fromJson(Map<String, dynamic> j) => MorfinGoal(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'shield',
        status: j['status']?.toString() ?? 'active',
        targetAmount: (j['targetAmount'] as num?)?.toInt() ?? 0,
        savedAmount: (j['savedAmount'] as num?)?.toInt() ?? 0,
        progressPercent: (j['progressPercent'] as num?)?.toInt() ?? 0,
      );
}

class WeeklyDayStatus {
  final String label;
  final String status; // done | today | upcoming

  const WeeklyDayStatus({required this.label, required this.status});

  factory WeeklyDayStatus.fromJson(Map<String, dynamic> j) => WeeklyDayStatus(
        label: j['label']?.toString() ?? '',
        status: j['status']?.toString() ?? 'upcoming',
      );
}

class CategoryBarItem {
  final String name;
  final int amount;
  final int percent;
  final bool healthy;

  const CategoryBarItem({
    required this.name,
    required this.amount,
    required this.percent,
    required this.healthy,
  });

  factory CategoryBarItem.fromJson(Map<String, dynamic> j) => CategoryBarItem(
        name: j['name']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        percent: (j['percent'] as num?)?.toInt() ?? 20,
        healthy: j['healthy'] == true,
      );
}

class WeeklyDayFlow {
  final String label;
  final String date;
  final int income;
  final int expense;
  final bool isToday;

  const WeeklyDayFlow({
    required this.label,
    required this.date,
    required this.income,
    required this.expense,
    required this.isToday,
  });

  factory WeeklyDayFlow.fromJson(Map<String, dynamic> j) => WeeklyDayFlow(
        label: j['label']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        income: (j['income'] as num?)?.toInt() ?? 0,
        expense: (j['expense'] as num?)?.toInt() ?? 0,
        isToday: j['isToday'] == true,
      );
}

class CashflowBarItem {
  final String label;
  final bool isIncome;
  final int amount;
  final double leftFrac;
  final double widthFrac;

  const CashflowBarItem({
    required this.label,
    required this.isIncome,
    required this.amount,
    required this.leftFrac,
    required this.widthFrac,
  });

  factory CashflowBarItem.fromJson(Map<String, dynamic> j) => CashflowBarItem(
        label: j['label']?.toString() ?? '',
        isIncome: j['isIncome'] == true,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        leftFrac: (j['leftFrac'] as num?)?.toDouble() ?? 0.05,
        widthFrac: (j['widthFrac'] as num?)?.toDouble() ?? 0.35,
      );
}

class DashboardSummary {
  final int totalBalance;
  final int totalIncome;
  final int totalExpense;
  final int savingsRate;
  final int hematStreakDays;
  final int budgetRemaining;
  final int budgetHealthPercent;
  final List<WeeklyDayStatus> weeklyDays;
  final List<WeeklyDayFlow> weeklySeries;
  final List<CashflowBarItem> weeklyCashflowBars;
  final List<CategoryBarItem> categoryBars;
  final int completedGoals;
  final int activeGoals;
  final int pausedGoals;

  const DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsRate,
    required this.hematStreakDays,
    required this.budgetRemaining,
    required this.budgetHealthPercent,
    required this.weeklyDays,
    required this.weeklySeries,
    required this.weeklyCashflowBars,
    required this.categoryBars,
    required this.completedGoals,
    required this.activeGoals,
    required this.pausedGoals,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    final gc = (j['goalCounts'] as Map<String, dynamic>?) ?? {};
    return DashboardSummary(
      totalBalance: (j['totalBalance'] as num?)?.toInt() ?? 0,
      totalIncome: (j['totalIncome'] as num?)?.toInt() ?? 0,
      totalExpense: (j['totalExpense'] as num?)?.toInt() ?? 0,
      savingsRate: (j['savingsRate'] as num?)?.toInt() ?? 0,
      hematStreakDays: (j['hematStreakDays'] as num?)?.toInt() ?? 25,
      budgetRemaining: (j['budgetRemaining'] as num?)?.toInt() ?? 0,
      budgetHealthPercent: (j['budgetHealthPercent'] as num?)?.toInt() ?? 72,
      weeklyDays: ((j['weeklyDays'] as List?) ?? [])
          .map((e) => WeeklyDayStatus.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weeklySeries: ((j['weeklySeries'] as List?) ?? [])
          .map((e) => WeeklyDayFlow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weeklyCashflowBars: ((j['weeklyCashflowBars'] as List?) ?? [])
          .map((e) => CashflowBarItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categoryBars: ((j['categoryBars'] as List?) ?? [])
          .map((e) => CategoryBarItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      completedGoals: (gc['completed'] as num?)?.toInt() ?? 0,
      activeGoals: (gc['active'] as num?)?.toInt() ?? 0,
      pausedGoals: (gc['paused'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardPayload {
  final DashboardSummary summary;
  final List<MorfinTransaction> transactions;
  final List<MorfinBudget> budgets;
  final List<MorfinWallet> wallets;
  final List<MorfinGoal> goals;

  const DashboardPayload({
    required this.summary,
    required this.transactions,
    required this.budgets,
    required this.wallets,
    required this.goals,
  });

  factory DashboardPayload.fromJson(Map<String, dynamic> j) => DashboardPayload(
        summary: DashboardSummary.fromJson(Map<String, dynamic>.from(j['summary'] as Map)),
        transactions: ((j['transactions'] as List?) ?? [])
            .map((e) => MorfinTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        budgets: ((j['budgets'] as List?) ?? [])
            .map((e) => MorfinBudget.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        wallets: ((j['wallets'] as List?) ?? [])
            .map((e) => MorfinWallet.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        goals: ((j['goals'] as List?) ?? [])
            .map((e) => MorfinGoal.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
