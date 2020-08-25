import 'package:cmdlineApp/cmdlineApp.dart';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:pedantic/pedantic.dart';
import 'package:system_info/system_info.dart';
import 'package:intl/intl.dart';
import 'dart:io' as io show Platform, stdin, File, FileMode;

//Compile: dart2native main.dart -o cmdl.exe
//Future cmdline options
//cmdl.exe name=Ben --test
//cmdl.exe -n Ben -p

const int MEGABYTE = 1024 * 1024;
const String lock_file = 'cmdl.lock';
const String shared_mem_file = 'shm.file';

List<String> arg_paths = [];

Future<bool> createSHMFile() async {
  io.File(shared_mem_file).createSync();
  print('SHARED MEM FILE created');
  return true;
}

Future<bool> deleteFile(String filename) async {
  io.File(filename).delete();
  print('FILE $filename deleted');
  return true;
}

Future<bool> writetoSHMFile(List<String> content) async {
  var sink = io.File(shared_mem_file).openWrite(mode:io.FileMode.append);
  content.forEach((v) => sink.writeln(v));
  await sink.flush();
  await sink.close();
  return true;
}

Future<void> main(List<String> args) async {

  if (await io.File(lock_file).exists() == true ) {
    print('Another Instance is already running.');
    print('Writing content to shared mem file');

    await writetoSHMFile(args);
    return;
  }
  else {
    await io.File(lock_file).create()
        .then((io.File file) async {
      print('LOCK FILE created');
      //Create shared mem file
      await createSHMFile().then((bool c) async {
        await writetoSHMFile(args);
      });
    });
  }

  var paths;
  var myFile = io.File(shared_mem_file);

  paths = await myFile.readAsLinesSync();

  var sink = io.File('paths.file').openWrite(mode:io.FileMode.append);

  paths.forEach((v) => sink.writeln(v));

  await sink.flush();
  await sink.close();

  print('-----------------------------------------------------------------');
  print(paths);
  print('-----------------------------------------------------------------');

  //Get environment variables
  var environment_properties = io.Platform.environment;

  var date_time = DateTime.now();

  var datetime_properties = {
    'Local date time': date_time,
    'Local date time friendly': DateFormat.yMMMMEEEEd().format(date_time),
    'Current timezone offset to UTC': date_time.timeZoneOffset,
    'UTC date time':  date_time.toUtc(),
    'Timezone name': date_time.timeZoneName,
    'Milliseconds since Unix epoch': date_time.millisecondsSinceEpoch
  };

  var platform_properties = {
    'Executable used to run the script': io.Platform.executable,
    'Executable used to run the script after iws resolved':
    io.Platform.resolvedExecutable,
    'ExecutableArguments': io.Platform.executableArguments.toString(),
    'Abolsute script URI': io.Platform.script,
    'Dart runtime version': io.Platform.version,
    'Local hostname': io.Platform.localHostname,
    'Current locale name': io.Platform.localeName,
    'Number of (virt.) processors': io.Platform.numberOfProcessors,
    'OS path separator': io.Platform.pathSeparator,
    'isLinux': io.Platform.isLinux,
    'isFuchsia': io.Platform.isFuchsia,
    'isAndroid': io.Platform.isAndroid,
    'isMacOS': io.Platform.isMacOS,
    'isIOS': io.Platform.isIOS,
    'isWindows': io.Platform.isWindows,
    'Operating System': io.Platform.operatingSystem,
    'Operating System version': io.Platform.operatingSystemVersion,
    'Executable Packages': io.Platform.packageConfig
  };

  var processors = SysInfo.processors;

  // ignore: omit_local_variable_types
  Map<String,dynamic> processor_properties = {
    'Number of (phys.) processors':  processors.length
  };

  for (var processor in processors) {
    processor_properties['Socket${processor.socket}: Socket']= processor.socket;
    processor_properties['Socket${processor.socket}: Vendor']= processor.vendor;
    processor_properties['Socket${processor.socket}: Name']= processor.name;
    processor_properties['Socket${processor.socket}: Architecture'] = processor.architecture;
  }

  var system_properties = {
    'Kernel architecture': SysInfo.kernelArchitecture,
    'Kernel bitness': SysInfo.kernelBitness,
    'Kernel name': SysInfo.kernelName,
    'Kernel version': SysInfo.kernelVersion,
    'Operating system name': SysInfo.operatingSystemName,
    'Operating system version': SysInfo.operatingSystemVersion,
    'User directory': SysInfo.userDirectory,
    'User id': SysInfo.userId,
    'User name': SysInfo.userName,
    'User space bitness': SysInfo.userSpaceBitness,
    'Total physical memory': '${SysInfo.getTotalPhysicalMemory() ~/ MEGABYTE} MB',
    'Free physical memory': '${SysInfo.getFreePhysicalMemory() ~/ MEGABYTE} MB',
    'Total virtual memory': '${SysInfo.getTotalVirtualMemory() ~/ MEGABYTE} MB',
    'Free virtual memory': '${SysInfo.getFreeVirtualMemory() ~/ MEGABYTE} MB',
    'Virtual memory size': '${SysInfo.getVirtualMemorySize() ~/ MEGABYTE} MB'
  };

  datetime_properties.forEach((k,v) => print('${k}: ${v}'));
  platform_properties.forEach((k,v) => print('${k}: ${v}'));
  system_properties.forEach((k,v) => print('${k}: ${v}'));
  processor_properties.forEach((k,v) => print('${k}: ${v}'));
  environment_properties.forEach((k,v) => print('${k}: ${v}'));

  await deleteFile(shared_mem_file);
  await deleteFile(lock_file);

  // This is just used to keep the cmd window open
  var line = io.stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
}