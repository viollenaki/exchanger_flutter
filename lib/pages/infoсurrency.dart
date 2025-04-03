import 'package:flutter/material.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

class Currency extends StatefulWidget {
  const Currency({super.key});

  @override
  _CurrencyState createState() => _CurrencyState();
}

class _CurrencyState extends State<Currency> {
  bool hasChanges = false;

  Future<void> addCurrency(String name) async {
    if (name.isNotEmpty) {
      setState(() {
        globalCurrencies.add(name);
      });
      hasChanges = true;
      await http.get(Uri.parse('https://dair12.pythonanywhere.com/add_currency/?name=$name'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Currency name cannot be empty')),);
    }
  }

  Future<void> deleteCurrency(String name) async {
      setState(() {
        globalCurrencies.remove(name);
      });
      hasChanges = true;
      await http.get(Uri.parse('https://dair12.pythonanywhere.com/delete_currency/$name/'));
      await fetchGlobalTransactions(currentUser!);
      currencyHoldings= await fetchUserInventory(currentUser!);
  }

  void showAddCurrencyDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Currency'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Currency Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                addCurrency(controller.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Currency',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 28, color: Colors.amber),
          onPressed: () {
            Navigator.pop(context, hasChanges);
          },
        ),
        backgroundColor: Colors.grey[850],
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 23.0),
            child: IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () async {
                await fetchGlobalCurrencies();
                setState(() {});
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: globalCurrencies.isEmpty
                  ? Center(
                child: Text(
                  'No currencies available. Please add a currency.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: globalCurrencies.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.grey[800],
                    child: ListTile(
                      title: Text(
                        globalCurrencies[index],
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.white),
                        onPressed: () => deleteCurrency(globalCurrencies[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: showAddCurrencyDialog,
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
