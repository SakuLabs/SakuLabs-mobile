import 'dart:async';

class AppEvents {
  AppEvents._();

  static final StreamController<void> _taskChangedController =
      StreamController<void>.broadcast();

  static Stream<void> get taskChanged => _taskChangedController.stream;

  static void notifyTaskChanged() {
    if (!_taskChangedController.isClosed) {
      _taskChangedController.add(null);
    }
  }
}
