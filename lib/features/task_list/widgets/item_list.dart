import 'package:flutter/material.dart';
import 'package:habit_flow/features/task_list/models/habit.dart';

class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCompletion,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Habit> items;
  final void Function(Habit habit, String newItem) onEdit;
  final void Function(Habit habit) onDelete;
  final void Function(Habit habit) onToggleCompletion;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final habit = items[index];

        return ListTile(
          leading: Checkbox(
            value: habit.isCompletedToday,
            onChanged: (_) => onToggleCompletion(habit),
          ),
          title: Text(
            habit.title,
            style: habit.isCompletedToday
                ? const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  )
                : null,
          ),
          subtitle: Text('Streak: ${habit.currentStreak} Tage'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  TextEditingController editController = TextEditingController(
                    text: habit.title,
                  );
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Habit bearbeiten'),
                        content: TextField(
                          autofocus: true,
                          controller: editController,
                          decoration: const InputDecoration(
                            hintText: 'Habit bearbeiten',
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Abbrechen'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Speichern'),
                            onPressed: () {
                              onEdit(habit, editController.text);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  onDelete(habit);
                },
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) =>
          const Divider(thickness: 1, color: Colors.white10),
    );
  }
}
