# 📜 AdGuard Logger

AdGuard Logger is a powerful and extensible Dart logging library tailored for developers building complex and performance-critical applications. Whether you need detailed diagnostics during development or robust, scalable logging solutions in production, AdGuard Logger has you covered.


### Typical Use Cases

- **Application Debugging:** Track down issues quickly with detailed logs.
- **HTTP Request Monitoring:** Monitor and log network activity for analytics or debugging.
- **Audit Trails:** Maintain a secure, tamper-proof record of application activity.
- **Error Tracking:** Log and store stack traces to identify and resolve issues faster.
- **Custom Reporting:** Export logs in structured formats for external processing or compliance.

AdGuard Logger is designed to be both powerful and developer-friendly, making it the go-to solution for your logging needs in Dart and Flutter projects.

---

## 📖 Table of Contents

- [🚀 Features](#-features)
- [📦 Installation](#-installation)
- [📖 Getting Started](#-getting-started)
- [🔧 Append Logging Outputs with Appenders](#-append-logging-outputs-with-appenders)
- [✍️ Creating a Custom Appender](#️-creating-a-custom-appender)
- [📁 File Logging with Rotation](#-file-logging-with-rotation)
- [🧩 Extensions](#-extensions-for-adguard-logger)
- [🛠️ Customizing Log Output](#️-customizing-log-output)
- [📊 Metadata Management](#-metadata-management)
- [📦 Archiving Logs](#-archiving-logs)
- [🌐 HTTP Logging](#-http-logging)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

---

## 🚀 Features

- 🖥️ **Platform versatility:** Supports mobile, web, and desktop platforms with seamless integration.
- 📁 **File-based logging:** Automatically rotate logs based on file size or age for efficient storage management.
- 🛠️ **Customizable formatters:** Format logs using built-in options or define your own structured formats.
- 🌐 **HTTP logging extension:** Log HTTP requests and responses with detailed metadata.
- 📝 **Metadata support:** Track and manage metadata for logs, including size, creation date, and more.
- 📦 **Archive and backup:** Compress logs into `.zip` files for storage, sharing, or auditing purposes.
- 🧩 **Appender-based design:** Modular system to log to console, files, databases, or custom destinations.

---

## 📦 Installation

To get started with AdGuard Logger, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  adguard_logger: ^0.0.1
```

Install the package with the following command:

```bash
dart pub get
```

### 📂 Importing the Library

Once installed, you can import the library into your Dart project:

```dart
import 'package:adguard_logger/adguard_logger.dart';
```

---

## 📖 Getting Started

### Basic Usage

To quickly get started with AdGuard Logger, follow this example:

#### Example: Basic Logging

```dart
import 'package:adguard_logger/adguard_logger.dart';

void main() {
  final log = logger;
  
  final consoleLogAppender = ConsoleLogAppender();
  consoleLogAppender.attachToLogger(log);

  log.logInfo("Application started.");

  log.listenableLevel = LogLevel.debug; // Set log level to debug level for retrieving debug messages
  log.logDebug("Fetching data from server...");
  
  log.logError("An error occurred while fetching data.", error: Exception("Network error"));

  consoleLogAppender.detachFromLoggers();
}
```

#### Expected Console Output:

```plaintext
[AdGuard Log] [2001-01-00T01:00:01.191552] [info] [main] 
              Application started.

[AdGuard Log] [2001-01-00T01:00:01.894267] [debug] [main] 
              Fetching data from server...
            
[AdGuard Log] [2001-01-00T01:00:02.294567] [error] [main] 
              An error occurred while fetching data. 
              Exception: Network error
```

This basic setup uses the default logger instance and outputs logs directly to the console. AdGuard Logger automatically formats and timestamps each log entry.


AdGuard Logger provides a robust API with the following key components:

### Core Classes

- **BaseLogger:** The main interface for logging in AdGuard Logger.
- **FileLogAppender:** Logs messages to files with support for rotation policies.
- **HttpLoggerExtension:** Logs HTTP requests and responses for debugging and auditing.
- **MetaDataController:** Manages metadata for log files, such as size and creation timestamps.
- **LoggerBaseFormatter:** Base class for creating custom log formatters.

---

## 🔧 Append Logging Outputs with Appenders

### What Are Appenders?

Appenders determine *where* and *how* your logs are stored or displayed. AdGuard Logger includes:

- **ConsoleLogAppender:** Sends logs to the console.
- **FileLogAppender:** Logs to files with configurable rotation policies.
- **Custom appenders:** Create your own to integrate with APIs, databases, or other storage solutions.

### Adding Appenders to a Logger

```dart
void main() {
  final logger = Logger();

  // Add a console appender
  final consoleAppender = ConsoleLogAppender();
  consoleAppender.attachToLogger(logger);

  // Add a file appender for persistent logs
  final fileAppender = FileLogAppender(
    filePath: "logs/app.log",
    logStorage: FileLogStorage(),
  );
  fileAppender.attachToLogger(logger);

  logger.logInfo("Logs are now stored in both console and file.");
}
```

---

## ✍️ Creating a Custom Appender

AdGuard Logger allows developers to extend its functionality by creating custom appenders:

### Example: Logging to a Cloud Service

```dart
class CloudLogAppender extends BaseLogAppender {
  final CloudService cloudService;

  CloudLogAppender(this.cloudService);

  @override
  FutureOr<void> handle(LogRecord record) async {
    await cloudService.sendLog({
      'message': record.message,
      'level': record.level.name,
      'timestamp': record.timeLog.toString(),
    });
  }
}
```

### Using the Custom Appender

```dart
void main() {
  final logger = Logger();
  final cloudAppender = CloudLogAppender(CloudService());
  cloudAppender.attachToLogger(logger);

  logger.logInfo("This log is sent to the cloud.");
}
```

---

## 📁 File Logging with Rotation

AdGuard Logger provides a robust `FileLogAppender` that supports file rotation to manage log size and age effectively.

### How Rotation Works

1. **By Size:** When a file exceeds the `rotationFileLimit`, it is renamed and a new file is created.
2. **By Age:** Files older than the specified `containmentDaysDuration` are archived or deleted.
3. **Custom Policies:** You can implement your own rotation logic using `RotationFileController`.

### Setting Up File Rotation

```dart
final fileAppender = FileLogAppender(
  filePath: "logs/application_log",
  logStorage: FileLogStorage(),
  rotationFileController: RotationFileController(
    rotationFileLimit: 1024 * 1024, // 1 MB
    containmentDaysDuration: 7,    // Retain logs for 7 days
  ),
);

logger.attachAppender(fileAppender);
```

### Platform-Specific Storage

AdGuard Logger handles file storage differently depending on the platform:

- **IO Platforms (e.g., Android, iOS, macOS):** Logs are stored in the device's local file system.
- **Web Platforms:** Logs are stored using IndexedDB (IDB), a browser-native database, ensuring efficient and persistent logging without requiring additional permissions.
  
 #### How Logs Are Stored in IndexedDB:
  
  - **Store Configuration:** Logs are saved in an object store named `logs`.
  - **Indexing:** Each log file's name acts as the index key, allowing efficient retrieval of logs based on their associated filenames.
  - **Log Entries:** Each entry is stored as a JSON object, with keys representing:
    - `file_name`: The name of the file (index key).
    - `data`: The formatted log message or metadata.
  - **Rotation Policies:** AdGuard Logger uses the `RotationFileController` to manage file size and age within IndexedDB. Rotated files are tracked and deleted as per the defined policies.

 #### Viewing Logs in the Browser:
  
  1. Open your browser's Developer Tools.
  2. Navigate to the **Application** tab.
  3. Under **Storage**, expand **IndexedDB**.
  4. Select the database created by AdGuard Logger (usually named after the logger instance).
  5. Open the `logs` object store to view the stored log entries.

Both implementations ensure that logs are rotated and stored efficiently, adhering to the specified rotation policies.

### Advanced Configuration

- **Custom Formatter:** Customize how logs are formatted before writing them to files.
- **Dynamic Paths:** Use environment variables or runtime configurations for log paths.
- **Parallel Storage:** Write logs to multiple destinations simultaneously.

---


## 🧩 Extensions for AdGuard Logger

Extensions in AdGuard Logger allow you to extend the logging functionality without modifying the core library. They are modular components designed to handle specific tasks, such as HTTP request/response logging or integrating with third-party services.

### Built-in Extensions

- **HttpLoggerExtension:** Logs HTTP requests and responses, providing useful insights into network activities.
  
  #### Example: Using `HttpLoggerExtension`
  ```dart
  import 'package:adguard_logger/adguard_logger.dart';
  import 'package:http/http.dart' as http;

  void main() async {
   final logger = Logger(
    extensions: [
      HttpLoggerExtension(),
    ],
  );

    final response = await http.get(Uri.parse("https://example.com"));
  }
  ```

  This extension captures and logs HTTP requests and responses, including the method, URL, status code, and error messages (if any).

  ```bash
  [AdGuard Log] [2001-01-11T00:00:32.912078] [debug] [CustomHttpLoggerExtension.logHttpResponse] 
              GET to https://test.com/test completed..
              Id=ajpxw
              Status=200
  ```

---

## 🛠️ Customizing Log Output

AdGuard Logger supports custom formatters to control how logs appear:

### Example: JSON Formatter

```dart
class JsonFormatter extends LoggerBaseFormatter {
  @override
  StringBuffer formatToStringBuffer(LogRecord record, StringBuffer sb) {
    sb.write(jsonEncode({
      'level': record.level.name,
      'message': record.message,
      'timestamp': record.timeLog.toString(),
    }));
    return sb;
  }
}
```

### Using the Custom Formatter

```dart
final formatter = JsonFormatter();
final consoleAppender = ConsoleLogAppender(formatter: formatter);

logger.attachAppender(consoleAppender);
logger.logDebug("This log is formatted in JSON.");
```

---

## 📊 Metadata Management

Metadata allows you to track properties of log files, such as size, creation date, and length. This is essential for managing log rotation and storage policies effectively.

In most cases, **you don't need to manage metadata manually**. When using `FileLogAppender`, metadata management is fully automated. The appender internally utilizes `MetaDataController` to handle all operations, such as inserting, updating, and deleting metadata. This ensures seamless rotation and efficient storage without requiring additional intervention.

#### Example (Manual Metadata Management - Advanced Use Case):

Although manual metadata handling is typically unnecessary, you can use the `MetaDataController` directly if required:

```dart
final metadataController = MetaDataController(
  "/path/to/metadata",
  flushDebounceDuration: Duration(seconds: 2),
);

// Insert custom metadata
metadataController.insertMetadata(LogMetaData(
  id: "log1",
  creationDate: DateTime.now(),
  lengthInBytes: 1024,
));
```

---

## 📦 Archiving Logs

Older logs can be archived into `.zip` files for efficient storage or sharing:

```dart
final archiveData = await fileAppender.archiveData(
  lastModifiedDuration: Duration(days: 7),
);

await File("logs_archive.zip").writeAsBytes(archiveData);
```

---

## 🌐 HTTP Logging

Track HTTP requests and responses with `HttpLoggerExtension`:

```dart
import 'package:http/http.dart' as http;

void main() async {
  final httpLogger = HttpLoggerExtension();
  logger.attachExtension(httpLogger);

  final response = await http.get(Uri.parse("https://example.com"));
  httpLogger.logHttpResponse(response);
}
```

---

## 🤝 Contributing

Contributions are welcome! Please submit issues or pull requests on GitHub.

---

## 📜 License

This project is licensed under the MIT License. See the LICENSE file for more details.
