// lib/src/extensions/locator_extensions.dart

import '../core/nx_locator.dart';

/// Custom extension to provide alternative syntax
///
/// WARNING: This is non-standard and not recommended.
/// Use nx.get<Type>() instead for standard usage.
extension NxLocatorExtensions on NxLocator {
  /// Alternative syntax that mimics what you wanted
  /// Usage: NxLocator.instance.call<BookingRepo>() or NxLocator.instance<BookingRepo>()
  T call<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
  }) {
    return get<T>(instanceName: instanceName, param1: param1, param2: param2);
  }
}

/// Function-style locator that enables the syntax you want
/// Usage: locator<BookingRepo>()
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
