import 'package:flutter/material.dart';

class Event extends StatefulWidget {
  const Event({super.key});

  @override
  State<Event> createState() => _EventState();
}

class _EventState extends State<Event> {
  bool _isPagination = false; // Flag for pagination toggle
  final TextEditingController _searchController = TextEditingController();
  final List<String> _transactions = [
    "Transaction 1",
    "Transaction 2",
    "Transaction 3",
    "Transaction 4",
    "Transaction 5",
    "Transaction 6",
    "Transaction 7",
    "Transaction 1",
    "Transaction 2",
    "Transaction 3",
    "Transaction 4",
    "Transaction 5",
    "Transaction 6",
    "Transaction 7",
    "Transaction 1",
    "Transaction 2",
    "Transaction 3",
    "Transaction 4",
    "Transaction 5",
    "Transaction 6",
    "Transaction 7",
    "Transaction 1",
    "Transaction 2",
    "Transaction 3",
    "Transaction 4",
    "Transaction 5",
    "Transaction 6",
    "Transaction 7",
    "Transaction 1",
    "Transaction 2",
    "Transaction 3",
    "Transaction 4",
    "Transaction 5",
    "Transaction 6",
    "Transaction 7",
    "Transaction 1",
    "Transaction 2",
    "Transaction 3",
    "Transaction 4",
    "Transaction 5",
    "Transaction 6",
    "Transaction 7",
    
  ];
  List<String> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _filteredTransactions = _transactions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                            .where((transaction) => transaction
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
                              return ListTile(
                                title: Text(
                                  _filteredTransactions[index],
                                  style: const TextStyle(color: Colors.black),
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
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [blueGradientStart, blueGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'История операций',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
                  child: _isPagination
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                                _transactions[index]);
                          },
                        )
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(
                                _transactions[index]);
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

  Widget _buildTransactionCard(String transaction) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(12),
      child: Text(
        transaction,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
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