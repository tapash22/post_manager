import 'package:flutter/material.dart';

import '../../data/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text('${post.id}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'User ${post.userId}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (canManage)
                    PopupMenuButton<_PostAction>(
                      tooltip: 'Post actions',
                      onSelected: (action) {
                        switch (action) {
                          case _PostAction.edit:
                            onEdit();
                          case _PostAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _PostAction.edit,
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: _PostAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                post.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PostAction { edit, delete }
