class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.releaseNotes,
    this.apkDownloadUrl,
  });

  final String version;
  final String releaseNotes;
  final String? apkDownloadUrl;
}
