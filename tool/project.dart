import "dart:io";
import "package:build_tools/build_shell.dart";
import "package:build_tools/build_tools.dart";
import "package:build_tools/build_utils.dart";
import "package:file_utils/file_utils.dart";

const String CHANGE_LOG = "tool/change.log";
const String CHANGELOG_MD = "CHANGELOG.md";
const String EXAMPLE_DART = "example/example.dart";
const String PUBSPEC_YAML = "pubspec.yaml";
const String README_MD = "README.md";
const String README_MD_IN = "tool/README.md.in";

void main(List<String> args) {
  // Change directory to root
  FileUtils.chdir("..");

  file(CHANGELOG_MD, [CHANGE_LOG], (Target t, Map args) {
    writeChangelogMd();
  });

  file(README_MD_IN, [], (Target t, Map args) {
    FileUtils.touch([t.name], create: true);
  });

  file(README_MD, [README_MD_IN, PUBSPEC_YAML, EXAMPLE_DART], (Target t, Map args) {
    var sources = t.sources.toList();
    var template = new File(sources.removeAt(0)).readAsStringSync();
    // Remove "pubspec.yaml"
    sources.removeAt(0);
    for (var filename in sources) {
      var text = new File(filename).readAsStringSync();
      template = template.replaceFirst("{{$filename}}", text);
    }

    template = template.replaceFirst("{{DESCRIPTION}}", getDescription());
    template = template.replaceFirst("{{VERSION}}", getVersion());
    //

    new File(t.name).writeAsStringSync(template);
  });

  target("default", ["git:status"], null, description: "git status");

  target("git:status", [], (Target t, Map args) {
    return exec("git", ["status", "--short"]);
  }, description: "git status --short");

  target("git:add", [], (Target t, Map args) {
    return exec("git", ["add", "--all"]);
  }, description: "git add --all");

  target("git:commit", [CHANGELOG_MD, README_MD, "git:add"], (Target t, Map args) {
    var message = args["m"];
    if (message == null || message.isEmpty) {
      print("Please, specify the `commit` message with --m option");
      return -1;
    }

    return exec("git", ["commit", "-m", message]);
  }, description: "git commit, --m \"message\"");

  after(["git:commit"], (Target t, Map args) {
    var version = incrementVersion(getVersion());
    print("Change the project version to '$version' (Y/N)?");
    if (stdin.readLineSync().toLowerCase().startsWith("y")) {
      updateVersion(version);
      print("Version switched to $version");
    }
  });

  target("git:push", [], (Target t, Map args) {
    // TODO: The `exec git push` does not show the prompt on Windows.
    // But on Posix everything works as expected.
    // Problem in the "git" or in the Dart VM "stdxxx" streams.
    return exec("git", ["push", "origin", "master"]);
  }, description: "git push origin master");

  target("log:changes", [], (Target t, Map args) {
    var message = args["m"];
    if (message == null || message.isEmpty) {
      print("Please, specify the `message` with --m option");
      return -1;
    }

    logChanges(message);
  }, description: "log changes, --m message", reusable: true);

  target("prj:changelog", [CHANGELOG_MD], null, description: "generate '$CHANGELOG_MD'", reusable: true);

  target("prj:readme", [README_MD], null, description: "generate '$README_MD'", reusable: true);

  target("prj:version", [], (Target t, Map args) {
    print("Version: ${getVersion()}");
  }, description: "display version", reusable: true);

  new BuildShell().run(args).then((exitCode) => exit(exitCode));
}

String getDescription() {
  var file = new File(PUBSPEC_YAML);
  var lines = file.readAsLinesSync();
  var description = "";
  for (var line in lines) {
    if (line.startsWith("description")) {
      var index = line.indexOf(":");
      if (index != -1 && line.length > index + 1) {
        description = line.substring(index + 1).trim();
      }
    }
  }

  return description;
}

String getVersion() {
  var file = new File(PUBSPEC_YAML);
  var lines = file.readAsLinesSync();
  var version = "0.0.1";
  for (var line in lines) {
    if (line.startsWith("version")) {
      var index = line.indexOf(":");
      if (index != -1 && line.length > index + 1) {
        version = line.substring(index + 1).trim();
      }
    }
  }

  return version;
}

String incrementVersion(String version) {
  var parts = version.split(".");
  if (parts.length < 3) {
    return version;
  }

  var patch = int.parse(parts[2], onError: (x) => null);
  if (patch == null) {
    return version;
  }

  parts[2] = ++patch;
  parts.length = 3;
  return parts.join(".");
}

void logChanges(String message) {
  if (message == null || message.isEmpty) {
    return;
  }

  FileUtils.touch([CHANGE_LOG], create: true);
  var file = new File(CHANGE_LOG);
  var length = file.lengthSync();
  var fp = file.openSync(mode: FileMode.APPEND);
  var sb = new StringBuffer();
  if (length != 0) {
    sb.writeln();
  }

  sb.write("${getVersion()} $message");
  fp.writeStringSync(sb.toString());
  fp.closeSync();
}

void updateVersion(String version) {
  var file = new File(PUBSPEC_YAML);
  var found = false;
  var lines = file.readAsLinesSync();
  var sb = new StringBuffer();
  for (var line in lines) {
    if (line.startsWith("version")) {
      found = true;
      break;
    }
  }

  if (!found) {
    var pos = lines.length == 0 ? 0 : 1;
    lines.insert(pos, "version: $version");
  }

  for (var line in lines) {
    if (line.startsWith("version")) {
      sb.writeln("version: $version");
    } else {
      sb.writeln(line);
    }
  }

  var string = sb.toString();
  file.writeAsStringSync(string);
}

void writeChangelogMd() {
  FileUtils.touch([CHANGELOG_MD], create: true);
  var log = new File(CHANGE_LOG);
  if (!log.existsSync()) {
    return;
  }

  var lines = log.readAsLinesSync();
  lines = lines.reversed.toList();
  var versions = <String, List<String>>{};
  for (var line in lines) {
    var index = line.indexOf(" ");
    if (index != -1) {
      var version = line.substring(0, index);
      var message = line.substring(index + 1).trimLeft();
      var messages = versions[version];
      if (messages == null) {
        messages = <String>[];
        versions[version] = messages;
      }

      messages.add(message);
    }
  }

  var sb = new StringBuffer();
  for (var version in versions.keys) {
    sb.writeln("## ${version}");
    sb.writeln();
    var messages = versions[version];
    messages.sort((a, b) => a.compareTo(b));
    for (var message in messages) {
      sb.writeln("- $message");
    }

    sb.writeln();
  }

  var md = new File(CHANGELOG_MD);
  md.writeAsStringSync(sb.toString());
}
