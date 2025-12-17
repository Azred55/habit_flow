import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:habit_flow/core/router/app_router.dart';
import 'package:habit_flow/features/quotes/data/quote_service.dart';
import 'package:habit_flow/features/quotes/models/quote.dart';
import 'package:habit_flow/features/task_list/models/habit.dart';
import 'package:habit_flow/features/task_list/widgets/empty_content.dart';
import 'package:habit_flow/features/task_list/widgets/item_list.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  Box<Habit> get _habitBox => Hive.box<Habit>(Habit.boxName);
  final QuoteService _quoteService = QuoteService();

  Quote? _quote;
  bool _isQuoteLoading = false;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Flow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
      body: ValueListenableBuilder<Box<Habit>>(
        valueListenable: _habitBox.listenable(),
        builder: (context, box, _) {
          final habits = box.values.toList(growable: false);
          final completedCount =
              habits.where((habit) => habit.isCompletedToday).length;
          final bestStreak = habits.fold<int>(
            0,
            (previousValue, habit) =>
                habit.currentStreak > previousValue ? habit.currentStreak : previousValue,
          );

          return RefreshIndicator(
            onRefresh: _refreshContent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: [
                _buildQuoteCard(context),
                const SizedBox(height: 16),
                _buildStreakCard(
                  context,
                  completedCount: completedCount,
                  totalHabits: habits.length,
                  bestStreak: bestStreak,
                ),
                const SizedBox(height: 16),
                if (habits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: EmptyContent(),
                  )
                else
                  ItemList(
                    items: habits,
                    onEdit: _editHabit,
                    onDelete: _deleteHabit,
                    onToggleCompletion: _toggleHabitCompletion,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddHabitDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neuen Habit anlegen'),
          content: TextField(
            autofocus: true,
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'z. B. 10 Minuten laufen',
            ),
            onSubmitted: (_) => _submitNewHabit(controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => _submitNewHabit(controller),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void _submitNewHabit(TextEditingController controller) {
    final text = controller.text.trim();

    if (text.isEmpty) {
      HapticFeedback.mediumImpact();
      return;
    }

    _habitBox.add(Habit(title: text));
    Navigator.of(context).pop();
  }

  void _editHabit(Habit habit, String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) {
      return;
    }

    habit.title = trimmed;
    habit.save();
  }

  void _deleteHabit(Habit habit) {
    habit.delete();
  }

  void _toggleHabitCompletion(Habit habit) {
    if (habit.isCompletedToday) {
      habit.resetCompletion();
    } else {
      habit.markCompletedToday();
    }
    habit.save();
  }

  Future<void> _loadQuote() async {
    if (mounted) {
      setState(() {
        _isQuoteLoading = true;
        _quoteError = null;
      });
    }

    try {
      final quote = await _quoteService.fetchRandomQuote();
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _quoteError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _quoteError = 'Zitat konnte nicht geladen werden. Bitte versuche es erneut.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isQuoteLoading = false;
        });
      }
    }
  }

  Future<void> _refreshContent() async {
    await _loadQuote();
  }

  Widget _buildQuoteCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBackground = LinearGradient(
      colors: [
        colorScheme.primary,
        colorScheme.primary.withValues(alpha: 0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.format_quote, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Motivationszitat',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isQuoteLoading ? null : _loadQuote,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isQuoteLoading && _quote == null)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (_quoteError != null)
            Text(
              _quoteError!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            )
          else if (_quote != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '„${_quote!.text}“',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _quote!.author,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ],
            )
          else
            Text(
              'Ziehe nach unten, um ein neues Zitat zu laden.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context, {
      required int completedCount,
    required int totalHabits,
    required int bestStreak,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Heutiger Fortschritt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalHabits == 0
                ? 'Lege deinen ersten Habit an, um loszulegen!'
                : '$completedCount von $totalHabits Habits erledigt',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Text(
            'Bester Streak',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$bestStreak',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                bestStreak == 1 ? 'Tag' : 'Tage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ein Tag Pause setzt den Streak zurück.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
