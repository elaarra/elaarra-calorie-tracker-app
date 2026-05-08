import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

// ── Data model ────────────────────────────────────────────────
class LogEntry {
  final int calories;
  final String? name;
  final String? label;
  final DateTime loggedAt;

  LogEntry({
    required this.calories,
    this.name,
    this.label,
    required this.loggedAt,
  });
}

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  // ── Hardcoded for now — will connect to real data later ──
  final int _dailyTarget = 1650;
  DateTime _selectedDate = DateTime.now();

  // Entries keyed by date string yyyy-MM-dd
  final Map<String, List<LogEntry>> _allEntries = {
    _todayKey(DateTime.now()): [
      LogEntry(calories: 320, name: 'Porridge with berries', label: 'Breakfast', loggedAt: DateTime.now().subtract(const Duration(hours: 6))),
      LogEntry(calories: 480, name: 'Grilled chicken salad', label: 'Lunch', loggedAt: DateTime.now().subtract(const Duration(hours: 3))),
      LogEntry(calories: 140, name: 'Greek yoghurt', label: 'Snack', loggedAt: DateTime.now().subtract(const Duration(hours: 1))),
    ],
  };

  static String _todayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _selectedKey => _todayKey(_selectedDate);

  List<LogEntry> get _entries => _allEntries[_selectedKey] ?? [];

  int get _consumed => _entries.fold(0, (sum, e) => sum + e.calories);
  int get _remaining => (_dailyTarget - _consumed).clamp(0, _dailyTarget);
  double get _progress => (_consumed / _dailyTarget).clamp(0.0, 1.0);
  bool get _isOver => _consumed > _dailyTarget;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    final diff = DateTime.now().difference(_selectedDate).inDays;
    if (diff == 1) return 'Yesterday';
    return '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}';
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  // ── Calendar picker ───────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cream,
              onPrimary: AppColors.darkBrown,
              surface: AppColors.midBrown,
              onSurface: AppColors.cream,
            ),
            dialogBackgroundColor: AppColors.darkBrown,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.cream),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Add entry flow ────────────────────────────────────────
  void _openAddFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEntrySheet(
        onSubmit: (entry) {
          setState(() {
            _allEntries.putIfAbsent(_selectedKey, () => []);
            _allEntries[_selectedKey]!.add(entry);
          });
        },
      ),
    );
  }

  // ── Delete entry ──────────────────────────────────────────
  void _deleteEntry(int index) {
    setState(() => _allEntries[_selectedKey]!.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.background),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSummary(),
                    const SizedBox(height: 16),
                    _buildEntryList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food diary',
          style: AppTextStyles.body,
        ),
        Text(
          _dateLabel,
          style: AppTextStyles.titleLarge.copyWith(fontSize: 40),
        ),
        const SizedBox(height: 12),
        // Date selector
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blush.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.cream,
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.blush,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary bar ───────────────────────────────────────────
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat('eaten', _consumed.toString()),
              Text('—', style: AppTextStyles.titleLarge.copyWith(
                fontSize: 18, color: AppColors.blush.withOpacity(0.4),
              )),
              _buildSummaryStat('goal', _dailyTarget.toString()),
              Text('=', style: AppTextStyles.titleLarge.copyWith(
                fontSize: 18, color: AppColors.blush.withOpacity(0.4),
              )),
              _buildSummaryStat(
                _isOver ? 'over' : 'left',
                _isOver
                    ? (_consumed - _dailyTarget).toString()
                    : _remaining.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                _isOver ? AppColors.sienna : AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 22)),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 9, letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ── Entry list ────────────────────────────────────────────
  Widget _buildEntryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOGGED',
          style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
        ),
        const SizedBox(height: 8),
        _entries.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  'Nothing logged yet.\nTap + to add your first entry.',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: _entries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final isLast = i == _entries.length - 1;
                    return Column(
                      children: [
                        Dismissible(
                          key: Key('$_selectedKey-$i-${e.loggedAt}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteEntry(i),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.3),
                              borderRadius: isLast
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )
                                  : BorderRadius.zero,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.cream,
                              size: 20,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.name ?? 'Entry',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.cream,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${e.label ?? 'No label'} · ${_formatTime(e.loggedAt)}',
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${e.calories}',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 0.5,
                            color: AppColors.blush.withOpacity(0.2),
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
        // Big plus button
        const SizedBox(height: 28),
        Center(
          child: GestureDetector(
            onTap: _openAddFlow,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkBrown.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.darkBrown,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Add entry bottom sheet ────────────────────────────────────
class _AddEntrySheet extends StatefulWidget {
  final Function(LogEntry) onSubmit;

  const _AddEntrySheet({required this.onSubmit});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  int _step = 0; // 0 = calories, 1 = detail
  final _calorieController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedLabel;

  final List<String> _labels = [
    'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Drinks', 'Other',
  ];

  int get _calories => int.tryParse(_calorieController.text) ?? 0;

  void _submitDirect() {
    if (_calories <= 0) return;
    widget.onSubmit(LogEntry(
      calories: _calories,
      name: null,
      label: null,
      loggedAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  void _submitWithDetail() {
    if (_calories <= 0) return;
    widget.onSubmit(LogEntry(
      calories: _calories,
      name: _nameController.text.isEmpty ? null : _nameController.text,
      label: _selectedLabel,
      loggedAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.blush, width: 0.3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.blush.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: Calories ──────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many\ncalories?',
          style: AppTextStyles.titleLarge.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the number — you can add detail after.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 20),
        // Calorie input
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _calorieController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.inputValue.copyWith(
                    fontSize: 48,
                    color: AppColors.darkBrown,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTextStyles.inputValue.copyWith(
                      fontSize: 48,
                      color: AppColors.blush.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                'kcal',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.sienna,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Add calories (no detail)
            Expanded(
              child: GestureDetector(
                onTap: _calories > 0 ? _submitDirect : null,
                child: AnimatedOpacity(
                  opacity: _calories > 0 ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.blush.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Add calories',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.cream,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No label',
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Add detail
            Expanded(
              child: GestureDetector(
                onTap: _calories > 0
                    ? () => setState(() => _step = 1)
                    : null,
                child: AnimatedOpacity(
                  opacity: _calories > 0 ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Add detail',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.button.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Name & label',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.midBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 1: Detail ────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a little\ndetail',
          style: AppTextStyles.titleLarge.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 4),
        Text(
          'Both optional — skip anything you don\'t need.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 20),
        // Calorie display (locked)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calories',
                style: AppTextStyles.label.copyWith(color: AppColors.blush),
              ),
              Text(
                '$_calories kcal',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Name input
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name (optional)',
                style: AppTextStyles.label.copyWith(
                  fontSize: 10,
                  color: AppColors.midBrown,
                ),
              ),
              TextField(
                controller: _nameController,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.darkBrown,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Pasta with tomato sauce',
                  hintStyle: AppTextStyles.label.copyWith(
                    color: AppColors.blush,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(top: 6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Label chips
        Text(
          'LABEL (OPTIONAL)',
          style: AppTextStyles.caption.copyWith(letterSpacing: 0.14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _labels.map((l) {
            final sel = _selectedLabel == l;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedLabel = sel ? null : l;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppColors.cream : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? AppColors.cream
                        : AppColors.blush.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  l,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: sel ? AppColors.darkBrown : AppColors.blush,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // Buttons
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Back',
                  style: AppTextStyles.button.copyWith(color: AppColors.cream),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _submitWithDetail,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Log it',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
