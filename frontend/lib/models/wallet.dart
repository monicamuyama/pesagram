class Wallet {
  final String id;
  final String currency;
  final double balance;
  final String address;
  final bool isActive;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.currency,
    required this.balance,
    required this.address,
    required this.isActive,
    required this.createdAt,
  });

  // Helper getter to calculate UGX equivalent
  double get ugxEquivalent {
    switch (currency) {
      case 'BTC':
        return balance * 162000000; // Mock BTC to UGX rate
      case 'USDT':
        return balance * 3720; // Mock USDT to UGX rate
      case 'UGX':
        return balance;
      default:
        return balance;
    }
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      currency: json['currency'],
      balance: (json['balance'] as num).toDouble(),
      address: json['address'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currency': currency,
      'balance': balance,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
