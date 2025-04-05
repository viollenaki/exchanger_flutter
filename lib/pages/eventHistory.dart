import 'package:currencies/globals.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import '../globals.dart';

class Transaction {
  final int id;
  final String operation;
  final String currency;
  final double quantity;
  final double rate;
  final String? description;
  final String createdAt;

  Transaction({
    required this.id,
    required this.operation,
    required this.currency,
    required this.quantity,
    required this.rate,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      operation: json['operation'] ?? '',
      currency: json['currency'] ?? '',
      quantity: double.parse(json['quantity'].toString()),
      rate: double.parse(json['rate'].toString()),
      description: json['description'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Event extends StatefulWidget {
  const Event({super.key});

  @override
  State<Event> createState() => _EventState();
}

class _EventState extends State<Event> {
  bool _isPagination = false; // Flag for pagination toggle
  final TextEditingController _searchController = TextEditingController();
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '0';

      final url = Uri.parse('https://dair12.pythonanywhere.com/transactions/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId, // Use user_id from SharedPreferences
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _transactions =
              data.map((json) => Transaction.fromJson(json)).toList();
          _filteredTransactions = _transactions;
          _isLoading = false;

          // Update global transactions for use in Information page
          globals.transactions = _transactions
              .map((transaction) => {
                    'id': transaction.id,
                    'operation': transaction.operation,
                    'currency': transaction.currency,
                    'quantity': transaction.quantity,
                    'rate': transaction.rate,
                    'description': transaction.description,
                    'created_at': transaction.createdAt,
                  })
              .toList();
        });
      } else {
        setState(() {
          _error = 'Failed to load transactions: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching transactions: $e';
        _isLoading = false;
      });
    }
  }

  void _openSearchModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF5ED), // Beige background
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Поиск транзакции...',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        _filteredTransactions = _transactions
                            .where((transaction) =>
                                transaction.currency
                                    .toLowerCase()
                                    .contains(query.toLowerCase()) ||
                                transaction.description!
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _filteredTransactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Ничего не найдено',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              return ListTile(
                                title: Text(
                                  '${transaction.operation.toUpperCase()} - ${transaction.currency} ${transaction.quantity}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                subtitle: Text(
                                  'Rate: ${transaction.rate} - ${transaction.createdAt}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color beige = Color(0xFFFDF5ED); // Beige background
    const Color blueGradientStart = Color(0xFF3A5ED9); // Blue gradient start
    const Color blueGradientEnd = Color(0xFFA7C3FF); // Blue gradient end

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: blueGradientStart,
        title: const Text(
          'История операций',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _openSearchModal,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _showPeriodDialog(context),
          ),
          IconButton(
            icon: Icon(
              _isPagination ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isPagination = !_isPagination;
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchTransactions,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Всего транзакций: ${_filteredTransactions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: beige,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: fetchTransactions,
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredTransactions.isEmpty
                              ? const Center(
                                  child: Text(
                                  'Транзакций не найдено',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black54),
                                ))
                              : _isPagination
                                  ? GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: _filteredTransactions.length,
                                      itemBuilder: (context, index) {
                                        return _buildTransactionCard(
                                            _filteredTransactions[index]);
                                      },
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredTransactions.length,
                                      itemBuilder: (context, index) {
                                        return _buildTransactionCard(
                                            _filteredTransactions[index]);
                                      },
                                    ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    Color statusColor =
        transaction.operation == 'sell' ? Colors.green : Colors.red;
    String operationText =
        transaction.operation == 'sell' ? 'Продажа' : 'Покупка';
    IconData operationIcon = transaction.operation == 'sell'
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(operationIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    operationText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                transaction.createdAt.split(' ')[0],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Quantity: ${transaction.quantity.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rate: ${transaction.rate.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Total: ${(transaction.quantity * transaction.rate).toStringAsFixed(2)} KGS',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (transaction.description != null &&
              transaction.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                transaction.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  void _showPeriodDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDF5ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption(Icons.date_range, 'Выбор диапазона'),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: [
                  _buildPeriodOption(Icons.all_inclusive, 'Все время'),
                  _buildPeriodOption(Icons.today, 'Выбрать день'),
                  _buildPeriodOption(Icons.calendar_view_week, 'Неделя'),
                  _buildPeriodOption(Icons.calendar_today, 'Сегодня'),
                  _buildPeriodOption(Icons.calendar_view_month, 'Месяц'),
                  _buildPeriodOption(Icons.event, 'Год'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }
}
