import 'package:flutter/material.dart';

import 'models.dart';
import 'pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = Store();
  await store.load();
  runApp(BudgetApp(store: store));
}

class BudgetApp extends StatelessWidget {
  final Store store;
  const BudgetApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.deepOrangeAccent,
        ),
      ),
      home: HomePage(store: store),
    );
  }
}

class HomePage extends StatefulWidget {
  final Store store;
  const HomePage({super.key, required this.store});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final pages = <Widget>[
          TransactionsPage(store: store, month: _month),
          BudgetPage(store: store, month: _month),
          StatsPage(store: store, month: _month),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Budget Tracker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage(store: store)),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Theme.of(context).primaryColorDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    SizedBox(
                      width: 190,
                      child: Text(
                        '${kMonths[_month.month - 1]} ${_month.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _shiftMonth(1),
                    ),
                  ],
                ),
              ),
              Expanded(child: pages[_tab]),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTxnPage(store: store)),
            ),
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt), label: 'Transactions'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart), label: 'Stats'),
            ],
          ),
        );
      },
    );
  }
}
