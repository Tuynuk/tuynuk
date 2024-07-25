import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

import 'package:safe_file_sender/dev/logger.dart';
import 'package:safe_file_sender/io/socket_client.dart';

class Downloader {
  const Downloader._();

  static final _downloader = FileDownloader();

  static Future<void> uploadFile(String filePath, String sessionId, String hmac,
      {Function(int percentage)? onSend,
      String subDir = "file_picker",
      BaseDirectory baseDirectory = BaseDirectory.temporary}) async {
    File? realFile;
    try {
      final temp = await getApplicationDocumentsDirectory();
      String fileName = filePath.split('/').last;
      logMessage("Uploading $fileName");
      realFile = File("${temp.path}/$fileName");
      final task = UploadTask(
        taskId: DateTime.now().millisecondsSinceEpoch.toString(),
        url: "NetworkUtils.uploadUrl",
        filename: fileName,
        updates: Updates.statusAndProgress,
        baseDirectory: baseDirectory,
        fields: {
          "sessionIdentifier": sessionId,
          "HMAC": hmac,
        },
      );
      var prev = 0;
      final response = await _downloader.upload(
        task,
        onStatus: (status) async {
          logMessage("Upload status : $status");
          if (status == TaskStatus.failed) {
            await realFile?.delete(recursive: true);
            return;
          }
        },
        onProgress: (progress) {
          final percent = (progress * 100).toInt();
          logMessage("Upload progress : $percent");
          if ((prev - percent).abs() > 20 || percent == 100) {
            onSend?.call(percent.abs());
            prev = percent;
          }
        },
      );
      // _downloader.cancelTaskWithId(task.taskId);
      // _downloader.destroy();
      logMessage("Response body upload : ${response.responseBody}");
      try {
        await realFile.delete(recursive: true);
      } catch (e) {
        logMessage("Cache clear failed");
      }
    } catch (e) {
      await realFile?.delete(recursive: true);
      logMessage("Upload error : ${e.toString()}");
    }
  }

  static Future<void> download(String fileId, String fileName,
      {Function(int percentage)? onReceive,
      Function()? onError,
      Function(String path)? onSuccess}) async {
    try {
      final task = DownloadTask(
        url: "${ConnectionClient.baseUrl}Files/GetFile?fileId=$fileId",
        updates: Updates.statusAndProgress,
        filename: fileName,
      );
      var prev = 0;
      _downloader.enqueue(
        task,
      );
      _downloader.registerCallbacks(
          taskProgressCallback: (TaskProgressUpdate update) async {
        final percent = (update.progress * 100).toInt();
        logMessage(update.task.headers);
        if ((prev - percent).abs() > 10 || percent == 100) {
          onReceive?.call(percent.abs());
          prev = percent;
          if (percent == 100) {
            final path =
                "${(await getApplicationDocumentsDirectory()).path}/$fileName";
            onSuccess?.call(path);
          }
        }
      });
    } catch (e) {
      logMessage("Download error : ${e.toString()}");
      onError?.call();
    }
  }

  void taskProgressCallback(TaskProgressUpdate update) {
    // print(
    //     'taskProgressCallback for ${update.task} with progress ${update.progress} '
    //         'and expected file size ${update.expectedFileSize}');
  }

  static void cancelAll() async {
    _downloader.cancelTaskWithId("uploading_id");
  }
}
