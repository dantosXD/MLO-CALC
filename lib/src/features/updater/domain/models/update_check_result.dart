import 'release_info.dart';

sealed class UpdateCheckResult {
  const UpdateCheckResult();

  const factory UpdateCheckResult.available(ReleaseInfo info) =
      UpdateAvailableResult;
  const factory UpdateCheckResult.upToDate() = UpToDateResult;
  const factory UpdateCheckResult.error(String message) = UpdateErrorResult;
}

class UpdateAvailableResult extends UpdateCheckResult {
  const UpdateAvailableResult(this.info);
  final ReleaseInfo info;
}

class UpToDateResult extends UpdateCheckResult {
  const UpToDateResult();
}

class UpdateErrorResult extends UpdateCheckResult {
  const UpdateErrorResult(this.message);
  final String message;
}
