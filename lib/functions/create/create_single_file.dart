import 'dart:io';

import 'package:path/path.dart';

import '../../common/utils/logger/LogUtils.dart';
import '../../common/utils/pubspec/pubspec_utils.dart';
import '../../core/internationalization.dart';
import '../../core/locales.g.dart';
import '../../core/structure.dart';
import '../../samples/interface/sample_interface.dart';
import '../sorter_imports/sort.dart';

File handleFileCreate(String name, String command, String on, bool extraFolder,
    Sample sample, String folderName,
    [sep = '_']) {
  final fileModel = Structure.model(name, command, extraFolder,
      on: on, folderName: folderName);
  String path = fileModel.path + '$sep${fileModel.commandName}.dart';
  sample.path = path;
  return sample.create();
}

/**
 * Create or edit the contents of a file
 */
File writeFile(String path, String content,
    {bool overwrite = false,
    bool skipFormatter = false,
    bool logger = true,
    bool skipRename = false,
    bool useRelativeImport = false}) {
  File _file = File(Structure.replaceAsExpected(path: path));

  if (!_file.existsSync() || overwrite) {
    if (!skipFormatter) {
      if (path.endsWith('.dart')) {
        try {
          content = sortImports(content, PubspecUtils.getProjectName(),
              renameImport: !skipRename,
              filePath: path,
              useRelative: useRelativeImport);
        } catch (e) {
          if (_file.existsSync()) {
            LogService.info(LocaleKeys.error_invalid_dart.trArgs([_file.path]));
          }
          rethrow;
        }
      }
    }
    if (!skipRename) {
      String separatorFileType = PubspecUtils.separatorFileType;
      if (separatorFileType.isNotEmpty) {
        _file = _file.existsSync()
            ? _file = _file
                .renameSync(replacePathTypeSeparator(path, separatorFileType))
            : File(replacePathTypeSeparator(path, separatorFileType));
      }
    }

    _file.createSync(recursive: true);
    _file.writeAsStringSync(content);

    if (logger) {
      LogService.success(
        LocaleKeys.sucess_file_created.trArgs(
          [basename(_file.path), _file.path],
        ),
      );
    }
  }
  return _file;
}

String replacePathTypeSeparator(String path, String separator) {
  if (separator.isNotEmpty) {
    int index = path.indexOf(RegExp(r'controller.dart|model.dart|provider.dart|'
        'binding.dart|view.dart|screen.dart|widget.dart|repository.dart'));
    if (index != -1) {
      List<String> chars = path.split('');
      index--;
      chars.removeAt(index);
      if (separator.length > 1) {
        chars.insert(index, separator[0]);
      } else {
        chars.insert(index, separator);
      }
      return chars.join();
    }
  }

  return path;
}
