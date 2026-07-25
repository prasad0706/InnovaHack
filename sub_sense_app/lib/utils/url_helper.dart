import 'url_helper/url_helper_stub.dart'
    if (dart.library.html) 'url_helper/url_helper_web.dart';

class LaunchUrlUtil {
  static void open(String url) {
    UrlHelper.openUrl(url);
  }
}
