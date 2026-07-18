import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if review was shown already
    final hasShown = prefs.getBool('hasShownReview') ?? false;
    if (hasShown) return;

    print('asking');
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // fallback
      await inAppReview.openStoreListing(
        appStoreId: '6792339229',
        microsoftStoreId: null,
      );
    }

    prefs.setBool('hasShownReview', true);
  }
}
