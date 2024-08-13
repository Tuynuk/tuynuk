import 'dart:io';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:safe_file_sender/dev/logger.dart';

class FileUtils {
  static String fileName(String path) =>
      path.split(Platform.pathSeparator).last;

  static File? fromSharedFile(SharedMediaFile? file) {
    if (file == null) return null;
    return File(file.path);
  }  static File? fromFileSystemEntity(FileSystemEntity? file) {
    if (file == null) return null;
    return File(file.path);
  }
}

extension FileExt on File {
  bool safeDelete() {
    try {
      delete();
      logMessage('File : $path deleted!');
      return true;
    } catch (e) {
      logMessage('Delete $path error');
      return false;
    }
  }
}
