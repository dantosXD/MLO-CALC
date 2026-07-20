import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/update_notifier.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final notifier = context.read<UpdateNotifier>();
    if (notifier.state != UpdateState.updateAvailable) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: notifier,
        child: const UpdateDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<UpdateNotifier>();
    final info = notifier.releaseInfo;
    final isDownloading = notifier.state == UpdateState.downloading;

    return AlertDialog(
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info != null) ...[
            Text('Version ${info.version} is ready to install.'),
            if (info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                info.releaseNotes,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
          if (isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: notifier.downloadProgress),
          ],
        ],
      ),
      actions: isDownloading
          ? null
          : [
              TextButton(
                onPressed: () {
                  notifier.dismissDialog();
                  Navigator.of(context).pop();
                },
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () async {
                  await notifier.install();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Update Now'),
              ),
            ],
    );
  }
}
