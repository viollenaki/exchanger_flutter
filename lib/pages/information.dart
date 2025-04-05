import 'package:flutter/material.dart';
import '../main.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class SalesData {
  final String
      category; // Для категориальных данных (месяц, день недели и т.д.)
  final double value; // Значение для отображения
  final String? country; // Дополнительное поле для круговой диаграммы

  SalesData(this.category, this.value, [this.country]);
}

// Добавляем новый класс для хранения данных транзакций по валютам
class CurrencyTransactionData {
  final String currency;
  final double sellAmount;
  final double buyAmount;

  CurrencyTransactionData(this.currency, this.sellAmount, this.buyAmount);
}

class Information extends StatefulWidget {
  const Information({super.key});

  @override
  _InformationState createState() => _InformationState();
}

class _InformationState extends State<Information> {
  bool _showHours = false;
  String? _selectedDay;

// Добавляем в класс _InformationState
  String _selectedCurrency = 'USD';
  String _selectedOperation = 'sell';

  Set<String> _getAvailableCurrencies() {
    return _transactions.map((t) => t['currency'] as String).toSet();
  }

  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _filteredTransactions =
        _transactions; // Изначально показываем все транзакции
  }

// Метод для фильтрации транзакций по дате
  void _filterTransactionsByDate(DateTimeRange? dateRange) {
    setState(() {
      _selectedDateRange = dateRange;

      if (dateRange == null) {
        _filteredTransactions = _transactions;
      } else {
        _filteredTransactions = _transactions.where((transaction) {
          try {
            DateTime date =
                DateFormat('yyyy-MM-dd HH:mm').parse(transaction['created_at']);
            return date.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
                date.isBefore(dateRange.end.add(Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
      }
    });
  }

// Метод для открытия диалога выбора даты
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly, // ← Убирает иконку карандаша
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      currentDate: DateTime.now(),
      saveText: 'Применить',
      helpText: '', // Убираем карандаш (поле ввода даты)
      builder: (context, child) {
        return Theme(
          data: ThemeData.light(), // Changed from ThemeData.dark()
          child: child!,
        );
      },
    );

    if (picked != null) {
      _filterTransactionsByDate(picked);
    }
  }

// Метод для подготовки данных по динамике курса
  List<SalesData> _prepareCurrencyTrendData() {
    // Фильтруем транзакции по выбранной валюте и типу операции
    var filteredTransactions = _filteredTransactions
        .where((t) =>
            t['currency'] == _selectedCurrency &&
            t['operation'] == _selectedOperation)
        .toList();

    // Группируем по дате и вычисляем средний курс
    Map<String, List<double>> dateRates = {};

    for (var transaction in filteredTransactions) {
      String date = transaction['created_at']
          .toString()
          .split(' ')[0]; // Берем только дату
      double rate = transaction['rate'];

      if (!dateRates.containsKey(date)) {
        dateRates[date] = [];
      }
      dateRates[date]!.add(rate);
    }

    // Сортируем по дате и вычисляем средний курс для каждой даты
    var sortedDates = dateRates.keys.toList()..sort();

    return sortedDates.map((date) {
      double avgRate =
          dateRates[date]!.reduce((a, b) => a + b) / dateRates[date]!.length;
      return SalesData(date, avgRate);
    }).toList();
  }

// Метод для подготовки данных по дням недели
  List<SalesData> _prepareWeeklyData() {
    // Группируем транзакции по дням недели
    Map<String, int> dayCounts = {
      'Пн': 0,
      'Вт': 0,
      'Ср': 0,
      'Чт': 0,
      'Пт': 0,
      'Сб': 0,
      'Вс': 0
    };

    for (var transaction in _filteredTransactions) {
      DateTime date =
          DateFormat('yyyy-MM-dd HH:mm').parse(transaction['created_at']);
      String day = _getDayOfWeek(date.weekday);
      dayCounts.update(day, (value) => value + 1);
    }

    return dayCounts.entries
        .map((e) => SalesData(e.key, e.value.toDouble()))
        .toList();
  }

// Метод для подготовки данных по часам выбранного дня
  List<SalesData> _prepareHourlyData(String day) {
    Map<int, int> hourCounts = {};
    for (int i = 0; i < 24; i++) {
      hourCounts[i] = 0;
    }

    for (var transaction in _filteredTransactions) {
      DateTime date =
          DateFormat('yyyy-MM-dd HH:mm').parse(transaction['created_at']);
      if (_getDayOfWeek(date.weekday) == day) {
        hourCounts.update(date.hour, (value) => value + 1);
      }
    }

    return hourCounts.entries
        .map((e) => SalesData('${e.key}:00', e.value.toDouble()))
        .toList();
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      case 7:
        return 'Вс';
      default:
        return '';
    }
  }

  // В классе _InformationState добавляем метод для подготовки данных
  List<CurrencyTransactionData> _prepareTransactionData() {
    Map<String, double> sellTotals = {};
    Map<String, double> buyTotals = {};

    for (var transaction in _filteredTransactions) {
      String currency = transaction['currency'];
      double quantity = transaction['quantity'];

      if (transaction['operation'] == 'sell') {
        sellTotals.update(currency, (value) => value + quantity,
            ifAbsent: () => quantity);
      } else if (transaction['operation'] == 'buy') {
        buyTotals.update(currency, (value) => value + quantity,
            ifAbsent: () => quantity);
      }
    }

    // Получаем список всех валют
    Set<String> allCurrencies = Set.from(sellTotals.keys)
      ..addAll(buyTotals.keys);

    // Сортируем валюты по убыванию общего объема
    var sortedCurrencies = allCurrencies.toList()
      ..sort((a, b) {
        double totalA = (sellTotals[a] ?? 0) + (buyTotals[a] ?? 0);
        double totalB = (sellTotals[b] ?? 0) + (buyTotals[b] ?? 0);
        return totalB.compareTo(totalA);
      });

    // Преобразуем в список CurrencyTransactionData
    return sortedCurrencies
        .map((currency) => CurrencyTransactionData(
              currency,
              sellTotals[currency] ?? 0,
              buyTotals[currency] ?? 0,
            ))
        .toList();
  }

  ////////////////////////////////////////////////////////////////////// список существующих транзакций
  List<Map<String, dynamic>> _transactions = [
    {
      'id': 1,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 758.3,
      'rate': 531.03,
      'description': 'Transaction 1',
      'created_at': '2025-03-18 11-55'
    },
    {
      'id': 2,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 554.48,
      'rate': 438.82,
      'description': 'Transaction 2',
      'created_at': '2025-03-13 22-30'
    },
    {
      'id': 3,
      'operation': 'buy',
      'currency': 'EUR',
      'quantity': 361.06,
      'rate': 326.28,
      'description': 'Transaction 3',
      'created_at': '2025-03-07 15-08'
    },
    {
      'id': 4,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 842.35,
      'rate': 226.09,
      'description': 'Transaction 4',
      'created_at': '2025-03-14 06-27'
    },
    {
      'id': 5,
      'operation': 'buy',
      'currency': 'EUR',
      'quantity': 851.42,
      'rate': 539.99,
      'description': 'Transaction 5',
      'created_at': '2025-03-31 08-04'
    },
    {
      'id': 6,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 552.44,
      'rate': 738.72,
      'description': 'Transaction 6',
      'created_at': '2025-03-12 20-26'
    },
    {
      'id': 7,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 605.74,
      'rate': 399.92,
      'description': 'Transaction 7',
      'created_at': '2025-03-23 23-58'
    },
    {
      'id': 8,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 986.05,
      'rate': 340.87,
      'description': 'Transaction 8',
      'created_at': '2025-03-21 12-33'
    },
    {
      'id': 9,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 137.2,
      'rate': 952.76,
      'description': 'Transaction 9',
      'created_at': '2025-03-10 03-23'
    },
    {
      'id': 10,
      'operation': 'buy',
      'currency': 'EUR',
      'quantity': 739.32,
      'rate': 354.53,
      'description': 'Transaction 10',
      'created_at': '2025-03-11 16-06'
    },
    {
      'id': 11,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 822.91,
      'rate': 434.82,
      'description': 'Transaction 11',
      'created_at': '2025-03-27 05-18'
    },
    {
      'id': 12,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 398.66,
      'rate': 213.98,
      'description': 'Transaction 12',
      'created_at': '2025-03-30 00-30'
    },
    {
      'id': 13,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 567.64,
      'rate': 960.08,
      'description': 'Transaction 13',
      'created_at': '2025-03-19 10-46'
    },
    {
      'id': 14,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 346.62,
      'rate': 690.46,
      'description': 'Transaction 14',
      'created_at': '2025-03-15 07-02'
    },
    {
      'id': 15,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 364.39,
      'rate': 658.41,
      'description': 'Transaction 15',
      'created_at': '2025-03-25 03-00'
    },
    {
      'id': 16,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 865.11,
      'rate': 194.99,
      'description': 'Transaction 16',
      'created_at': '2025-03-09 05-17'
    },
    {
      'id': 17,
      'operation': 'buy',
      'currency': 'EUR',
      'quantity': 514.04,
      'rate': 136.23,
      'description': 'Transaction 17',
      'created_at': '2025-03-27 05-34'
    },
    {
      'id': 18,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 356.42,
      'rate': 856.89,
      'description': 'Transaction 18',
      'created_at': '2025-03-01 06-56'
    },
    {
      'id': 19,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 252.12,
      'rate': 120.77,
      'description': 'Transaction 19',
      'created_at': '2025-03-17 20-24'
    },
    {
      'id': 20,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 21.87,
      'rate': 530.49,
      'description': 'Transaction 20',
      'created_at': '2025-03-26 22-24'
    },
    {
      'id': 21,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 903.63,
      'rate': 323.38,
      'description': 'Transaction 21',
      'created_at': '2025-03-14 23-44'
    },
    {
      'id': 22,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 888.04,
      'rate': 233.7,
      'description': 'Transaction 22',
      'created_at': '2025-03-24 05-44'
    },
    {
      'id': 23,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 164.74,
      'rate': 882.34,
      'description': 'Transaction 23',
      'created_at': '2025-03-26 21-35'
    },
    {
      'id': 24,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 395.61,
      'rate': 623.08,
      'description': 'Transaction 24',
      'created_at': '2025-03-02 08-14'
    },
    {
      'id': 25,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 682.21,
      'rate': 434.17,
      'description': 'Transaction 25',
      'created_at': '2025-03-22 20-44'
    },
    {
      'id': 26,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 903.74,
      'rate': 135.94,
      'description': 'Transaction 26',
      'created_at': '2025-04-01 18-53'
    },
    {
      'id': 27,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 40.23,
      'rate': 582.87,
      'description': 'Transaction 27',
      'created_at': '2025-03-28 10-25'
    },
    {
      'id': 28,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 684.14,
      'rate': 53.84,
      'description': 'Transaction 28',
      'created_at': '2025-03-11 23-56'
    },
    {
      'id': 29,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 932.83,
      'rate': 645.9,
      'description': 'Transaction 29',
      'created_at': '2025-03-23 04-15'
    },
    {
      'id': 30,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 521.71,
      'rate': 158.38,
      'description': 'Transaction 30',
      'created_at': '2025-03-17 06-55'
    },
    {
      'id': 31,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 451.58,
      'rate': 597.53,
      'description': 'Transaction 31',
      'created_at': '2025-03-27 21-45'
    },
    {
      'id': 32,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 371.73,
      'rate': 800.36,
      'description': 'Transaction 32',
      'created_at': '2025-03-20 04-51'
    },
    {
      'id': 33,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 144.5,
      'rate': 251.35,
      'description': 'Transaction 33',
      'created_at': '2025-03-19 22-38'
    },
    {
      'id': 34,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 577.9,
      'rate': 457.3,
      'description': 'Transaction 34',
      'created_at': '2025-04-02 22-45'
    },
    {
      'id': 35,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 193.04,
      'rate': 372.29,
      'description': 'Transaction 35',
      'created_at': '2025-03-20 10-59'
    },
    {
      'id': 36,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 691.41,
      'rate': 134.97,
      'description': 'Transaction 36',
      'created_at': '2025-03-17 22-50'
    },
    {
      'id': 37,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 369.49,
      'rate': 877.56,
      'description': 'Transaction 37',
      'created_at': '2025-03-28 13-45'
    },
    {
      'id': 38,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 791.53,
      'rate': 956.66,
      'description': 'Transaction 38',
      'created_at': '2025-03-18 17-42'
    },
    {
      'id': 39,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 48.69,
      'rate': 673.37,
      'description': 'Transaction 39',
      'created_at': '2025-03-09 15-15'
    },
    {
      'id': 40,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 378.84,
      'rate': 121.82,
      'description': 'Transaction 40',
      'created_at': '2025-03-27 02-55'
    },
    {
      'id': 41,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 655.81,
      'rate': 855.53,
      'description': 'Transaction 41',
      'created_at': '2025-03-19 08-21'
    },
    {
      'id': 42,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 500.97,
      'rate': 987.3,
      'description': 'Transaction 42',
      'created_at': '2025-03-31 07-54'
    },
    {
      'id': 43,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 27.22,
      'rate': 752.79,
      'description': 'Transaction 43',
      'created_at': '2025-03-15 04-49'
    },
    {
      'id': 44,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 576.15,
      'rate': 698.46,
      'description': 'Transaction 44',
      'created_at': '2025-03-27 20-40'
    },
    {
      'id': 45,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 106.17,
      'rate': 739.7,
      'description': 'Transaction 45',
      'created_at': '2025-03-30 09-40'
    },
    {
      'id': 46,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 109.82,
      'rate': 444.59,
      'description': 'Transaction 46',
      'created_at': '2025-03-30 01-57'
    },
    {
      'id': 47,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 80.42,
      'rate': 330.64,
      'description': 'Transaction 47',
      'created_at': '2025-03-01 20-38'
    },
    {
      'id': 48,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 330.94,
      'rate': 880.38,
      'description': 'Transaction 48',
      'created_at': '2025-03-10 15-10'
    },
    {
      'id': 49,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 306.81,
      'rate': 327.56,
      'description': 'Transaction 49',
      'created_at': '2025-03-05 15-40'
    },
    {
      'id': 50,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 504.01,
      'rate': 743.07,
      'description': 'Transaction 50',
      'created_at': '2025-03-18 07-13'
    },
    {
      'id': 51,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 23.74,
      'rate': 782.45,
      'description': 'Transaction 51',
      'created_at': '2025-03-16 02-02'
    },
    {
      'id': 52,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 153.34,
      'rate': 148.34,
      'description': 'Transaction 52',
      'created_at': '2025-03-30 15-00'
    },
    {
      'id': 53,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 636.34,
      'rate': 677.89,
      'description': 'Transaction 53',
      'created_at': '2025-03-09 16-14'
    },
    {
      'id': 54,
      'operation': 'buy',
      'currency': 'EUR',
      'quantity': 653.51,
      'rate': 76.78,
      'description': 'Transaction 54',
      'created_at': '2025-03-16 23-12'
    },
    {
      'id': 55,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 673.94,
      'rate': 367.72,
      'description': 'Transaction 55',
      'created_at': '2025-03-21 15-30'
    },
    {
      'id': 56,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 161.75,
      'rate': 886.25,
      'description': 'Transaction 56',
      'created_at': '2025-04-03 21-34'
    },
    {
      'id': 57,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 701.54,
      'rate': 244.32,
      'description': 'Transaction 57',
      'created_at': '2025-03-19 06-14'
    },
    {
      'id': 58,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 423.35,
      'rate': 664.46,
      'description': 'Transaction 58',
      'created_at': '2025-03-17 09-15'
    },
    {
      'id': 59,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 103.99,
      'rate': 985.68,
      'description': 'Transaction 59',
      'created_at': '2025-03-16 11-33'
    },
    {
      'id': 60,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 179.14,
      'rate': 850.13,
      'description': 'Transaction 60',
      'created_at': '2025-03-02 01-08'
    },
    {
      'id': 61,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 13.64,
      'rate': 279.03,
      'description': 'Transaction 61',
      'created_at': '2025-03-16 23-24'
    },
    {
      'id': 62,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 946.54,
      'rate': 260.67,
      'description': 'Transaction 62',
      'created_at': '2025-03-05 14-47'
    },
    {
      'id': 63,
      'operation': 'buy',
      'currency': 'EUR',
      'quantity': 309.01,
      'rate': 727.33,
      'description': 'Transaction 63',
      'created_at': '2025-03-22 02-52'
    },
    {
      'id': 64,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 138.88,
      'rate': 707.1,
      'description': 'Transaction 64',
      'created_at': '2025-03-14 11-36'
    },
    {
      'id': 65,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 791.69,
      'rate': 897.78,
      'description': 'Transaction 65',
      'created_at': '2025-03-05 12-42'
    },
    {
      'id': 66,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 621.5,
      'rate': 452.44,
      'description': 'Transaction 66',
      'created_at': '2025-03-27 08-58'
    },
    {
      'id': 67,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 903.46,
      'rate': 671.07,
      'description': 'Transaction 67',
      'created_at': '2025-03-18 22-29'
    },
    {
      'id': 68,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 722.59,
      'rate': 543.35,
      'description': 'Transaction 68',
      'created_at': '2025-03-15 00-25'
    },
    {
      'id': 69,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 380.71,
      'rate': 679.99,
      'description': 'Transaction 69',
      'created_at': '2025-03-31 12-58'
    },
    {
      'id': 70,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 603.57,
      'rate': 713.12,
      'description': 'Transaction 70',
      'created_at': '2025-03-06 02-26'
    },
    {
      'id': 71,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 633.85,
      'rate': 582.96,
      'description': 'Transaction 71',
      'created_at': '2025-03-24 12-10'
    },
    {
      'id': 72,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 420.87,
      'rate': 56.51,
      'description': 'Transaction 72',
      'created_at': '2025-03-22 23-57'
    },
    {
      'id': 73,
      'operation': 'buy',
      'currency': 'KGS',
      'quantity': 894.64,
      'rate': 198.6,
      'description': 'Transaction 73',
      'created_at': '2025-03-12 19-03'
    },
    {
      'id': 74,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 509.78,
      'rate': 643.61,
      'description': 'Transaction 74',
      'created_at': '2025-03-28 19-28'
    },
    {
      'id': 75,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 995.08,
      'rate': 546.68,
      'description': 'Transaction 75',
      'created_at': '2025-03-22 16-58'
    },
    {
      'id': 76,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 251.94,
      'rate': 770.53,
      'description': 'Transaction 76',
      'created_at': '2025-03-25 06-53'
    },
    {
      'id': 77,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 73.84,
      'rate': 986.7,
      'description': 'Transaction 77',
      'created_at': '2025-03-14 17-33'
    },
    {
      'id': 78,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 187.22,
      'rate': 352.7,
      'description': 'Transaction 78',
      'created_at': '2025-03-02 17-05'
    },
    {
      'id': 79,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 570.63,
      'rate': 816.12,
      'description': 'Transaction 79',
      'created_at': '2025-03-12 11-35'
    },
    {
      'id': 80,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 36.55,
      'rate': 203.48,
      'description': 'Transaction 80',
      'created_at': '2025-03-07 17-28'
    },
    {
      'id': 81,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 444.64,
      'rate': 318.56,
      'description': 'Transaction 81',
      'created_at': '2025-03-06 20-04'
    },
    {
      'id': 82,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 440.53,
      'rate': 380.38,
      'description': 'Transaction 82',
      'created_at': '2025-03-14 18-23'
    },
    {
      'id': 83,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 792.04,
      'rate': 69.62,
      'description': 'Transaction 83',
      'created_at': '2025-03-07 16-58'
    },
    {
      'id': 84,
      'operation': 'buy',
      'currency': 'CNY',
      'quantity': 599.32,
      'rate': 975.09,
      'description': 'Transaction 84',
      'created_at': '2025-03-21 12-39'
    },
    {
      'id': 85,
      'operation': 'sell',
      'currency': 'CNY',
      'quantity': 656.92,
      'rate': 291.01,
      'description': 'Transaction 85',
      'created_at': '2025-03-09 15-52'
    },
    {
      'id': 86,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 934.54,
      'rate': 729.75,
      'description': 'Transaction 86',
      'created_at': '2025-03-31 18-48'
    },
    {
      'id': 87,
      'operation': 'sell',
      'currency': 'EUR',
      'quantity': 906.74,
      'rate': 336.27,
      'description': 'Transaction 87',
      'created_at': '2025-03-17 06-54'
    },
    {
      'id': 88,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 896.03,
      'rate': 904.16,
      'description': 'Transaction 88',
      'created_at': '2025-03-31 14-40'
    },
    {
      'id': 89,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 46.0,
      'rate': 479.61,
      'description': 'Transaction 89',
      'created_at': '2025-03-03 01-31'
    },
    {
      'id': 90,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 765.81,
      'rate': 118.32,
      'description': 'Transaction 90',
      'created_at': '2025-03-31 22-48'
    },
    {
      'id': 91,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 379.07,
      'rate': 277.16,
      'description': 'Transaction 91',
      'created_at': '2025-03-02 19-57'
    },
    {
      'id': 92,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 758.94,
      'rate': 362.27,
      'description': 'Transaction 92',
      'created_at': '2025-03-16 17-01'
    },
    {
      'id': 93,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 313.25,
      'rate': 149.08,
      'description': 'Transaction 93',
      'created_at': '2025-03-06 19-08'
    },
    {
      'id': 94,
      'operation': 'sell',
      'currency': 'KGS',
      'quantity': 248.62,
      'rate': 681.33,
      'description': 'Transaction 94',
      'created_at': '2025-03-19 14-06'
    },
    {
      'id': 95,
      'operation': 'buy',
      'currency': 'USD',
      'quantity': 451.36,
      'rate': 476.69,
      'description': 'Transaction 95',
      'created_at': '2025-04-01 05-00'
    },
    {
      'id': 96,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 868.03,
      'rate': 893.72,
      'description': 'Transaction 96',
      'created_at': '2025-03-23 00-57'
    },
    {
      'id': 97,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 632.96,
      'rate': 515.34,
      'description': 'Transaction 97',
      'created_at': '2025-03-21 00-45'
    },
    {
      'id': 98,
      'operation': 'sell',
      'currency': 'RUB',
      'quantity': 975.8,
      'rate': 319.83,
      'description': 'Transaction 98',
      'created_at': '2025-03-17 15-21'
    },
    {
      'id': 99,
      'operation': 'buy',
      'currency': 'RUB',
      'quantity': 928.74,
      'rate': 349.3,
      'description': 'Transaction 99',
      'created_at': '2025-03-04 11-02'
    },
    {
      'id': 100,
      'operation': 'sell',
      'currency': 'USD',
      'quantity': 979.07,
      'rate': 80.38,
      'description': 'Transaction 100',
      'created_at': '2025-03-18 07-35'
    }
  ];

  // 🔹 Метод для заголовков секций
  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title,
          style: TextStyle(
              fontSize: 27, fontWeight: FontWeight.bold, color: Colors.black), // Changed from white
        ),
      ),
    );
  }

  double calculateTransactionSum(List<Map<String, dynamic>> transactions) {
    double totalSum = 0.0;

    for (var transaction in transactions) {
      double amount = transaction['quantity'] * transaction['rate'];

      if (transaction['operation'] == 'sell') {
        totalSum += amount; // Для продажи суммируем
      } else if (transaction['operation'] == 'buy') {
        totalSum -= amount; // Для покупки вычитаем
      }
    }

    return double.parse(
        totalSum.toStringAsFixed(2)); // Округляем до 2 знаков после запятой
  }

  // Метод для расчета распределения валют
  List<SalesData> _calculateCurrencyDistribution() {
    Map<String, double> currencyTotals = {};

    for (var transaction in _filteredTransactions) {
      double amount = transaction['quantity'] * transaction['rate'];
      String currency = transaction['currency'];

      if (transaction['operation'] == 'sell') {
        currencyTotals.update(currency, (value) => value + amount,
            ifAbsent: () => amount);
      } else if (transaction['operation'] == 'buy') {
        currencyTotals.update(currency, (value) => value - amount,
            ifAbsent: () => -amount);
      }
    }

    // Преобразуем в список SalesData
    return currencyTotals.entries
        .map((entry) => SalesData(entry.key, entry.value.abs(), entry.key))
        .toList();
  }

  // Метод сброса фильтра
void _resetFilter() {
  setState(() {
    _selectedDateRange = null;
    _filteredTransactions = _transactions;
  });
}


  @override
  Widget build(BuildContext context) {
    final currencyData = _calculateCurrencyDistribution();

    final data = _prepareTransactionData();

    /////////////////////////////////////////////////////////////////////////////////////////////////// Scaffold - основная структура экрана
    return Scaffold(
      backgroundColor: Colors.white, // Changed from Colors.black87
      /////////////////////////////////////////////////////////////////////////////////////////// AppBar - верхняя панель
      appBar: AppBar(
        backgroundColor: Colors.blue, // Changed from Colors.black
        title: const Text('Statistics', style: TextStyle(color: Colors.white)),
        centerTitle: true,

        // Добавляем кнопку сброса фильтра в leading
  leading: IconButton(
    icon: Icon(Icons.refresh, color: Colors.white), // Иконка сброса
    onPressed: _resetFilter, // Вызывает метод сброса
  ),

        //////////////////////////////////////////////////////////////////////////////// actions - список кнопок в AppBar
        actions: [
          // Иконка для открытия нового окна "Обзор"
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Открываем новое окно "Обзор" через push
              //Navigator.push(
                //context,
                //MaterialPageRoute(
                  //  builder: (context) =>
                        //Overview()), // Здесь создаем новый маршрут
              //);
            },
          ),

          // Иконка для экспорта в PDF
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () {
              // Логика для экспорта в PDF будет добавлена позже
            },
          ),

          // Иконка для экспорта в Excel
          IconButton(
            icon: Icon(Icons.table_chart, color: Colors.white),
            onPressed: () {
              // Логика для экспорта в Excel будет добавлена позже
            },
          ),


          // Иконка для фильтрации по датам
          IconButton(
            icon: Icon(Icons.calendar_today,
                color: Colors.white), // Иконка календаря
            onPressed: _showDateRangePicker,
          ),
        ],
      ),

      ////////////////////////////////////////// список динамических заголовков
      body: CustomScrollView(
        slivers: [
          // 🔹 Динамический заголовок
          SliverAppBar(
            expandedHeight: 100.0,

            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
  "Прибыль в Сомах: ${calculateTransactionSum(_filteredTransactions)}",
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold, 
    color: Colors.black,

    
  ),
),
if (_selectedDateRange != null)
  Text(
    "Период: ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_selectedDateRange!.end)}",
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      
    ),
  ),
                ],
              ),
              background: Container(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),

          //  график "По количеству транзакций", где синие - покупки, красные - продажи
          _buildSectionTitle("По количеству транзакций"),
          SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        "График показывает количество операций покупки (синие столбцы) и продажи (красные столбцы) по разным валютам. Чем выше столбец - тем больше операций было совершено с данной валютой.",
        style: TextStyle(color: Colors.black54, fontSize: 20), // Changed from white70
      ),
    ),
  ),
SliverToBoxAdapter(
            child: Container(
              height: 500,
              padding: EdgeInsets.all(16),
              child: SfCartesianChart(
                title: ChartTitle(text: 'Объем операций по валютам'),
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Валюта'),
                  labelPlacement: LabelPlacement.betweenTicks,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Количество'),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<CurrencyTransactionData, String>(
                    name: 'Продажи',
                    dataSource: data,
                    xValueMapper: (data, _) => data.currency,
                    yValueMapper: (data, _) => data.sellAmount,
                    color: Colors.red,
                    width: 0.5, // Ширина столбца
                    spacing: 0.2, // Отступ между группами
                  ),
                  ColumnSeries<CurrencyTransactionData, String>(
                    name: 'Покупки',
                    dataSource: data,
                    xValueMapper: (data, _) => data.currency,
                    yValueMapper: (data, _) => data.buyAmount,
                    color: Colors.blue,
                    width: 0.5, // Ширина столбца
                    spacing: 0.2, // Отступ между группами
                  ),
                ],
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(color: Colors.white),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  header: '',
                  format: 'point.x : point.y',
                  textStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),


          // динамический столбчатый график по дням недели (с детализацией по часам каждый)
          _buildSectionTitle("По дням недели"),
          SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(
      "На графике отображается активность операций по дням недели. Вы можете выбрать конкретный день, чтобы увидеть распределение транзакций по часам.",
      style: TextStyle(color: Colors.black54, fontSize: 20),
    ),
  ),
),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Кнопки дней недели
                SizedBox(
  height: 50,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDay == day ? Colors.blue : Colors.grey,
            foregroundColor: Colors.white, // Set text color to white
          ),
          onPressed: () {
            setState(() {
              if (_selectedDay == day && _showHours) {
                // Если уже показываем часы этого дня - возвращаем дни недели
                _showHours = false;
                _selectedDay = null;
              } else {
                // Иначе показываем часы выбранного дня
                _showHours = true;
                _selectedDay = day;
              }
            });
          },
          child: Text(day),
        ),
      );
    }).toList(),
  ),
),

                // сам столбчатый график, по дням или неделям  
                Container(
                  height: 500,
                  padding: EdgeInsets.all(16),
                  child: SfCartesianChart(
                    title: ChartTitle(
                        text: _showHours
                            ? 'Транзакции по часам ($_selectedDay)'
                            : 'Транзакции по дням недели'),
                    primaryXAxis: CategoryAxis(
                      title:
                          AxisTitle(text: _showHours ? 'Часы' : 'Дни недели'),
                    ),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Количество транзакций'),
                    ),
                    series: <ColumnSeries<SalesData, String>>[
                      ColumnSeries<SalesData, String>(
                        dataSource: _showHours
                            ? _prepareHourlyData(_selectedDay ?? 'Пн')
                            : _prepareWeeklyData(),
                        xValueMapper: (SalesData sales, _) => sales.category,
                        yValueMapper: (SalesData sales, _) => sales.value,
                        color: Colors.blue,
                        width: _showHours ? 0.2 : 0.4,
                      ),
                    ],
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x : point.y',
                    ),
                  ),
                ),
              ],
            ),
          ),


          // секция с линейным графиком
          _buildSectionTitle("По динамике роста валюты"),
          SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(
      "Линейный график демонстрирует изменение курса выбранной валюты за период. Вы можете сравнить динамику цен на покупку и продажу.",
      style: TextStyle(color: Colors.white70, fontSize: 20),
    ),
  ),
),

          SliverToBoxAdapter(
            child: Container(
              height: 500,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Выбор валюты и типа операции
                  Row(
                    children: [
                      // Выбор валюты
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _getAvailableCurrencies().map((currency) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(currency),
                                  selected: _selectedCurrency == currency,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCurrency = currency;
                                    });
                                  },
                                  selectedColor: Colors.blue,
                                  labelStyle: TextStyle(
                                    color: _selectedCurrency == currency
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Выбор операции
                      DropdownButton<String>(
                        value: _selectedOperation,
                        items: [
                          DropdownMenuItem(
                            value: 'sell',
                            child: Text('Продажа',
                                style: TextStyle(color: Colors.red)),
                          ),
                          DropdownMenuItem(
                            value: 'buy',
                            child: Text('Покупка',
                                style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedOperation = value!;
                          });
                        },
                        dropdownColor: Colors.white,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),

                  // График
                  Expanded(
                    child: SfCartesianChart(
                      title: ChartTitle(
                        text:
                            'Динамика курса $_selectedCurrency ($_selectedOperation)',
                        textStyle: TextStyle(color: Colors.black), // Changed from white
                      ),
                      primaryXAxis: CategoryAxis(
                        title: AxisTitle(text: 'Дата'),
                        labelRotation: -45,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Курс'),
                      ),
                      series: <LineSeries<SalesData, String>>[
                        LineSeries<SalesData, String>(
                          dataSource: _prepareCurrencyTrendData(),
                          xValueMapper: (SalesData sales, _) => sales.category,
                          yValueMapper: (SalesData sales, _) => sales.value,
                          color: _selectedOperation == 'sell'
                              ? Colors.red
                              : Colors.blue,
                          markerSettings: MarkerSettings(isVisible: true),
                          animationDuration: 1000,
                        ),
                      ],
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        textStyle: TextStyle(color: Colors.black), // Changed from white
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: 'Дата: point.x\nКурс: point.y',
                        textStyle: TextStyle(color: Colors.black), // Changed from white
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),


          // круговой график по объему валют 
          _buildSectionTitle("По объёму валюты"),
          SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(  
      "Круговая диаграмма показывает распределение операций по валютам. Размер сегмента соответствует доле операций с каждой валютой.",
      style: TextStyle(color: Colors.white70, fontSize: 20),
    ),
  ),
),

          SliverToBoxAdapter(
            child: Container(
              height: 500,
              padding: EdgeInsets.all(16),
              child: SfCircularChart(
                title: ChartTitle(text: 'Распределение по валютам'),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
                series: <PieSeries<SalesData, String>>[
                  PieSeries<SalesData, String>(
                    dataSource: currencyData,
                    xValueMapper: (SalesData data, _) => data.country ?? '',
                    yValueMapper: (SalesData data, _) => data.value,
                    dataLabelMapper: (SalesData data, _) =>
                        '${data.country}: ${data.value.toStringAsFixed(2)}',
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                      textStyle: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    radius: '70%',
                    explode: true,
                    explodeIndex: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}