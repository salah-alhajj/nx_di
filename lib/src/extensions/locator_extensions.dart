// lib/src/extensions/locator_extensions.dart

import '../core/nx_locator.dart';

/// Custom extension to provide alternative syntax
///
/// WARNING: This is non-standard and not recommended.
/// ignore_for_file: unused_import, undefined_identifier
extension NxLocatorExtensions on NxLocator {
  /// Alternative syntax that mimics what you wanted
  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return get<T>(instanceName: instanceName, param1: param1, param2: param2);
  }
}

/// Function-style locator that enables the syntax you want
T locator<T extends Object>({
  String? instanceName,
  dynamic param1,
  dynamic param2,
}) {
  return NxLocator.instance.get<T>(
    instanceName: instanceName,
    param1: param1,
    param2: param2,
  );
}
