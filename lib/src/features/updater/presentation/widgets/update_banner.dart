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
        final showBanner = notifier.state == UpdateState.updateAvailable &&
            notifier.dialogDismissed;

        return Column(
          children: [
            if (showBanner)
              MaterialBanner(
                content: Text(
                  'Version ${notifier.releaseInfo?.version ?? ''} available',
                ),
                actions: [
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
