import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

// ---------------------------------------------------------------------------
// Transactions tab
// ---------------------------------------------------------------------------

class TransactionsPage extends StatelessWidget {
  final Store store;
  final DateTime month;
  const TransactionsPage({super.key, required this.store, required this.month});

  Widget _summaryCell(String label, double v, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              money(v, store.currency),
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = store.monthTxns(month);
    final inc = store.incomeOf(month);
    final exp = store.expenseOf(month);

    final children = <Widget>[
      Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              _summaryCell('INCOME', inc, Colors.green.shade700),
              _summaryCell('EXPENSES', exp, Colors.red.shade700),
              _summaryCell('BALANCE', inc - exp,
                  inc - exp >= 0 ? Colors.teal.shade800 : Colors.red.shade700),
            ],
          ),
        ),
      ),
    ];

    if (list.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(48),
        child: Text(
          'No transactions this month.\nTap + to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      ));
    }

    DateTime? lastDay;
    for (final t in list) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (lastDay != day) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            dayHeader(day),
            style: const TextStyle(
                color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ));
        lastDay = day;
      }
      final c = store.cat(t.categoryId);
      children.add(Dismissible(
        key: ValueKey(t.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          store.deleteTxn(t.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(label: 'UNDO', onPressed: () => store.addTxn(t)),
          ));
        },
        child: Container(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c.colorValue,
              child: Icon(c.iconData, color: Colors.white),
            ),
            title: Text(c.name),
            subtitle: t.note.isEmpty ? null : Text(t.note),
            trailing: Text(
              '${t.income ? '+' : '-'}${money(t.amount, store.currency)}',
              style: TextStyle(
                color: t.income ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddTxnPage(store: store, existing: t)),
            ),
          ),
        ),
      ));
      children.add(const Divider(height: 1));
    }
    children.add(const SizedBox(height: 90));
    return ListView(children: children);
  }
}

// ---------------------------------------------------------------------------
// Add / edit transaction
// ---------------------------------------------------------------------------

class AddTxnPage extends StatefulWidget {
  final Store store;
  final Txn? existing;
  const AddTxnPage({super.key, required this.store, this.existing});

  @override
  State<AddTxnPage> createState() => _AddTxnPageState();
}

class _AddTxnPageState extends State<AddTxnPage> {
  late bool _income;
  late TextEditingController _amount;
  late TextEditingController _note;
  String? _catId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _income = e?.income ?? false;
    _amount = TextEditingController(
        text: e == null ? '' : e.amount.toStringAsFixed(2));
    _note = TextEditingController(text: e?.note ?? '');
    _catId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amt == null || amt <= 0) {
      _msg('Enter an amount greater than zero');
      return;
    }
    if (_catId == null) {
      _msg('Pick a category');
      return;
    }
    final store = widget.store;
    final t = Txn(
      id: widget.existing?.id ?? store.newId(),
      amount: amt,
      income: _income,
      categoryId: _catId!,
      note: _note.text.trim(),
      date: _date,
    );
    if (widget.existing == null) {
      await store.addTxn(t);
    } else {
      await store.updateTxn(t);
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _typeChip(String label, bool value) {
    return ChoiceChip(
      label: Text(label),
      selected: _income == value,
      onSelected: (_) => setState(() {
        _income = value;
        _catId = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final cats = store.categories.where((c) => c.income == _income).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add transaction' : 'Edit transaction'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _typeChip('Expense', false),
              const SizedBox(width: 12),
              _typeChip('Income', true),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: widget.existing == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${store.currency} ',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Category',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats)
                ChoiceChip(
                  avatar: Icon(c.iconData,
                      size: 18,
                      color: _catId == c.id ? Colors.white : c.colorValue),
                  label: Text(c.name),
                  selected: _catId == c.id,
                  selectedColor: c.colorValue,
                  labelStyle:
                      TextStyle(color: _catId == c.id ? Colors.white : null),
                  onSelected: (_) => setState(() => _catId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(fmtDate(_date)),
            onTap: _pickDate,
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              icon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('SAVE'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget tab
// ---------------------------------------------------------------------------

class BudgetPage extends StatelessWidget {
  final Store store;
  final DateTime month;
  const BudgetPage({super.key, required this.store, required this.month});

  Future<void> _editBudget(BuildContext context, Category c) async {
    final ctl = TextEditingController(
      text: store.budgets[c.id]?.toStringAsFixed(0) ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c.name} budget'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monthly limit',
            helperText: 'Leave empty to remove the budget',
            prefixText: '${store.currency} ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctl.text),
              child: const Text('SAVE')),
        ],
      ),
    );
    if (result != null) {
      await store.setBudget(
          c.id, double.tryParse(result.trim().replaceAll(',', '')) ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = store.categories.where((c) => !c.income).toList();
    double totalBudget = 0;
    double totalSpent = 0;
    for (final c in cats) {
      final b = store.budgets[c.id];
      if (b != null) {
        totalBudget += b;
        totalSpent += store.spentIn(c.id, month);
      }
    }
    final left = totalBudget - totalSpent;

    final children = <Widget>[
      Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: totalBudget <= 0
              ? const Text(
                  'Tap a category below to set a monthly budget.',
                  style: TextStyle(color: Colors.black54),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL BUDGET',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${money(totalSpent, store.currency)} of ${money(totalBudget, store.currency)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (totalSpent / totalBudget).clamp(0.0, 1.0),
                      minHeight: 8,
                      color: totalSpent > totalBudget
                          ? Colors.red
                          : Colors.teal,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      left >= 0
                          ? '${money(left, store.currency)} left'
                          : 'Over budget by ${money(-left, store.currency)}',
                      style: TextStyle(
                          color: left >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    ];

    for (final c in cats) {
      final limit = store.budgets[c.id];
      final spent = store.spentIn(c.id, month);
      final over = limit != null && spent > limit;
      children.add(ListTile(
        leading: CircleAvatar(
          backgroundColor: c.colorValue,
          child: Icon(c.iconData, color: Colors.white),
        ),
        title: Text(c.name),
        subtitle: limit == null
            ? Text(spent > 0
                ? 'Spent ${money(spent, store.currency)} - no budget set'
                : 'No budget set')
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (spent / limit).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: over ? Colors.red : c.colorValue,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${money(spent, store.currency)} of ${money(limit, store.currency)}',
                      style: TextStyle(
                          color: over ? Colors.red.shade700 : Colors.black54),
                    ),
                  ],
                ),
              ),
        onTap: () => _editBudget(context, c),
      ));
      children.add(const Divider(height: 1));
    }
    children.add(const SizedBox(height: 90));
    return ListView(children: children);
  }
}

// ---------------------------------------------------------------------------
// Stats tab
// ---------------------------------------------------------------------------

class PiePainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color holeColor;
  PiePainter(this.values, this.colors, this.holeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final side = size.shortestSide;
    final rect = Rect.fromLTWH(
            (size.width - side) / 2, (size.height - side) / 2, side, side)
        .deflate(8);
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      start += sweep;
    }
    canvas.drawCircle(
        rect.center, rect.width * 0.3, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(covariant PiePainter old) => true;
}

class StatsPage extends StatefulWidget {
  final Store store;
  final DateTime month;
  const StatsPage({super.key, required this.store, required this.month});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _income = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final byCat = <String, double>{};
    for (final t
        in store.monthTxns(widget.month).where((t) => t.income == _income)) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (a, e) => a + e.value);

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Expenses'),
              selected: !_income,
              onSelected: (_) => setState(() => _income = false),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Income'),
              selected: _income,
              onSelected: (_) => setState(() => _income = true),
            ),
          ],
        ),
      ),
    ];

    if (entries.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(48),
        child: Text(
          'Nothing to show for this month yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      ));
    } else {
      children.add(SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(double.infinity, 240),
              painter: PiePainter(
                entries.map((e) => e.value).toList(),
                entries.map((e) => store.cat(e.key).colorValue).toList(),
                Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            Text(
              money(total, store.currency),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ));
      for (final e in entries) {
        final c = store.cat(e.key);
        children.add(ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: c.colorValue,
            child: Icon(c.iconData, size: 16, color: Colors.white),
          ),
          title: Text(c.name),
          subtitle: Text('${(e.value / total * 100).toStringAsFixed(1)}%'),
          trailing: Text(
            money(e.value, store.currency),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ));
      }
    }
    children.add(const SizedBox(height: 90));
    return ListView(children: children);
  }
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class SettingsPage extends StatefulWidget {
  final Store store;
  const SettingsPage({super.key, required this.store});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _cur;

  @override
  void initState() {
    super.initState();
    _cur = TextEditingController(text: widget.store.currency);
  }

  @override
  void dispose() {
    _cur.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final nameCtl = TextEditingController();
    bool income = false;
    int color = 4;
    String icon = 'label';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: !income,
                      onSelected: (_) => setS(() => income = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: income,
                      onSelected: (_) => setS(() => income = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < kPalette.length; i++)
                      GestureDetector(
                        onTap: () => setS(() => color = i),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: kPalette[i],
                          child: color == i
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in kIcons.entries)
                      GestureDetector(
                        onTap: () => setS(() => icon = entry.key),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: icon == entry.key
                              ? kPalette[color]
                              : Colors.grey.shade300,
                          child: Icon(
                            entry.value,
                            size: 18,
                            color: icon == entry.key
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL')),
            TextButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                if (name.isEmpty) return;
                await widget.store.addCategory(Category(
                  id: 'c_${widget.store.newId()}',
                  name: name,
                  icon: icon,
                  color: color,
                  income: income,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'This removes every transaction, budget and custom category. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DELETE')),
        ],
      ),
    );
    if (ok == true) await widget.store.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _cur,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Currency symbol',
                  helperText: 'Shown next to every amount',
                ),
                onChanged: (v) => store.setCurrency(v.trim()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text('Categories',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('ADD'),
                  ),
                ],
              ),
              for (final c in store.categories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: c.colorValue,
                    child: Icon(c.iconData, color: Colors.white),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.income ? 'Income' : 'Expense'),
                  trailing: c.id.startsWith('c_')
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => store.deleteCategory(c.id),
                        )
                      : null,
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _confirmClear,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Delete all data',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }
}
