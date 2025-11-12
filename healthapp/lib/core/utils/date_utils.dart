class DateUtilsX {
  static int nowMs() => DateTime.now().millisecondsSinceEpoch;

  static DateTime fromMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);
}

