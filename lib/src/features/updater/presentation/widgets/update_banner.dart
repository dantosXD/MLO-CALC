import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/providers/update_notifier.dart';

class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateNotifier>(
      builder: (context, notifier, _) {
        final isDownloading = notifier.state == UpdateState.downloading;
        final showBanner = (notifier.state == UpdateState.updateAvailable &&
                notifier.dialogDismissed) ||
            isDownloading;

        return Column(
          children: [
            if (showBanner)
              MaterialBanner(
                content: isDownloading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Downloading update (${(notifier.downloadProgress * 100).toInt()}%)...',
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: notifier.downloadProgress > 0
                                ? notifier.downloadProgress
                                : null,
                          ),
                        ],
                      )
                    : Text(
                        'Version ${notifier.releaseInfo?.version ?? ''} available',
                      ),
                actions: isDownloading
                    ? [const SizedBox.shrink()]
                    : [
                        TextButton(
                          onPressed: notifier.resetDialogDismissed,
                          child: const Text('Dismiss'),
                        ),
                        TextButton(
                          onPressed: notifier.install,
                          child: const Text('Install'),
                        ),
                      ],
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
