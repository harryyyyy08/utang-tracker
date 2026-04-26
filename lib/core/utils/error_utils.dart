bool isNetworkError(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('clientexception') ||
      msg.contains('connection refused') ||
      msg.contains('no address associated') ||
      msg.contains('network is unreachable');
}

String friendlyError(Object error) {
  if (isNetworkError(error)) {
    return 'Walang koneksyon sa internet. Subukan ulit kapag may signal.';
  }
  return 'May error na naganap. Subukan ulit.';
}
