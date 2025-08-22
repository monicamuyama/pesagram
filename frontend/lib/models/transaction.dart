class Transaction {
  final String id;
  final String type; // send, receive, swap
  final String fromCurrency;
  final String? toCurrency; // Optional for receive transactions
  final double amount;
  final double? convertedAmount; // For swaps - amount in toCurrency
  final double? fee;
  final String status;
  final String? recipient; // Phone, address, etc.
  final String? recipientType; // phone, address, bank
  final String? hash; // Transaction hash
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.fromCurrency,
    this.toCurrency,
    required this.amount,
    this.convertedAmount,
    this.fee,
    required this.status,
    this.recipient,
    this.recipientType,
    this.hash,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      fromCurrency: json['fromCurrency'],
      toCurrency: json['toCurrency'],
      amount: (json['amount'] as num).toDouble(),
      convertedAmount: json['convertedAmount'] != null
          ? (json['convertedAmount'] as num).toDouble()
          : null,
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : null,
      status: json['status'],
      recipient: json['recipient'],
      recipientType: json['recipientType'],
      hash: json['hash'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
      'convertedAmount': convertedAmount,
      'fee': fee,
      'status': status,
      'recipient': recipient,
      'recipientType': recipientType,
      'hash': hash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper getter for display purposes
  double get ugxAmount {
    if (fromCurrency == 'UGX') return amount;
    if (toCurrency == 'UGX' && convertedAmount != null) return convertedAmount!;
    // Default conversion rate for display (should use real rates)
    switch (fromCurrency) {
      case 'BTC':
        return amount * 162000000; // Mock BTC to UGX rate
      case 'USDT':
        return amount * 3720; // Mock USDT to UGX rate
      default:
        return amount;
    }
  }

  String get displayAmount {
    switch (fromCurrency) {
      case 'BTC':
        return '${amount.toStringAsFixed(8)} $fromCurrency';
      case 'USDT':
        return '\$${amount.toStringAsFixed(2)}';
      case 'UGX':
        return 'UGX ${amount.toStringAsFixed(0)}';
      default:
        return '${amount.toStringAsFixed(2)} $fromCurrency';
    }
  }
}
