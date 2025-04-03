import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'dart:convert';

class Event extends StatefulWidget {
  const Event({super.key});

  @override
  State<Event> createState() => _EventState();
}

class _EventState extends State<Event> {
  List transactions = [];
  String selectedCurrency = 'All';
  String selectedOperation = 'All';
  List<int> selectedForDeletion = [];
  Map<String, dynamic> editingTransaction = {};


  @override
  void initState() {
    super.initState();
    // Ensure transactions are fetched and initialized correctly
    if (globalTransactions.isEmpty) {
      globalTransactions = [];
    }
  }

  List getFilteredTransactions() {
    if (globalTransactions.isEmpty) {
      return [];
    }
    return globalTransactions.where((transaction) {
      if (selectedCurrency != 'All' && transaction['currency'] != selectedCurrency) {
        return false;
      }
      if (selectedOperation != 'All' && transaction['operation'] != selectedOperation) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> deleteSelectedTransactions() async {
    List<int> ids = List.from(selectedForDeletion);
    setState(() {
      globalTransactions.removeWhere((transaction) =>
          selectedForDeletion.contains(transaction['id']));
      selectedForDeletion.clear();
    });

    final url = Uri.parse('https://dair12.pythonanywhere.com/transaction/delete/');
    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({'ids': ids}),
    );
  }

  Future<void> saveEditedTransaction(Map<String, dynamic> transaction) async {
    setState(() {
      final index = globalTransactions.indexWhere(
              (existingTransaction) => existingTransaction['id'] == transaction['id']);
      if (index != -1) {
        globalTransactions[index] = transaction;
      }
    });
    final url = Uri.parse('https://dair12.pythonanywhere.com/transaction/edit/${transaction["id"]}/');
    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(transaction),
    );
  }

  void showEditDialog(Map<String, dynamic> transaction) {
    editingTransaction = {...transaction};
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: editingTransaction['quantity'].toString()),
                decoration: const InputDecoration(labelText: 'Quantity'),
                onChanged: (value) {
                  editingTransaction['quantity'] = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                controller: TextEditingController(text: editingTransaction['rate'].toString()),
                decoration: const InputDecoration(labelText: 'Rate'),
                onChanged: (value) {
                  editingTransaction['rate'] = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                saveEditedTransaction(editingTransaction);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = getFilteredTransactions();

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Events', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  dropdownColor: Colors.grey[800],
                  value: selectedCurrency,
                  style: const TextStyle(color: Colors.white),
                  items: ['All', ...globalCurrencies].map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCurrency = value!;
                    });
                  },
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOperation = selectedOperation == 'buy' ? 'All' : 'buy';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedOperation == 'buy'
                              ? Colors.blue
                              : Colors.grey[800],
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 24),
                        child: const Text(
                          'Buy',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOperation = selectedOperation == 'sell' ? 'All' : 'sell';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedOperation == 'sell'
                              ? Colors.blue
                              : Colors.grey[800],
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 24),
                        child: const Text(
                          'Sell',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey[800],
              child: Row(
                children: const [
                  Expanded(child: Text('Date', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('Time', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('Operation', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('Currency', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('Rate', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('Total', textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
            Expanded(
              child: filteredTransactions.isEmpty
                  ? const Center(
                child: Text(
                  'No transactions available',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    final isSelectedForDeletion =
                    selectedForDeletion.contains(transaction['id']);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelectedForDeletion) {
                            selectedForDeletion.remove(transaction['id']);
                          } else {
                            selectedForDeletion.add(transaction['id']);
                          }
                        });
                      },
                      child: Container(
                        color: isSelectedForDeletion
                            ? Colors.red.shade200
                            : Colors.transparent,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                showEditDialog(transaction);
                              },
                            ),
                            Expanded(
                              child: Text(
                                transaction['created_at'].split(' ')[0],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                transaction['created_at'].split(' ')[1],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                transaction['operation'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                transaction['currency'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                transaction['quantity'].toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                transaction['rate'].toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                (transaction['quantity'] * transaction['rate'])
                                    .toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: isSelectedForDeletion
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isSelectedForDeletion) {
                                    selectedForDeletion
                                        .remove(transaction['id']);
                                  } else {
                                    selectedForDeletion
                                        .add(transaction['id']);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                deleteSelectedTransactions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
