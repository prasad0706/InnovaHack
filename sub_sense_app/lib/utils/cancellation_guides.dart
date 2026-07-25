class CancellationGuide {
  final String merchant;
  final String directUrl;
  final List<String> steps;
  final String supportEmail;
  final String emailTemplate;

  const CancellationGuide({
    required this.merchant,
    required this.directUrl,
    required this.steps,
    required this.supportEmail,
    required this.emailTemplate,
  });

  static CancellationGuide getForMerchant(String merchantName) {
    final name = merchantName.toLowerCase();

    if (name.contains('netflix')) {
      return const CancellationGuide(
        merchant: 'Netflix',
        directUrl: 'https://www.netflix.com/youraccount',
        steps: [
          'Log in to Netflix at netflix.com/youraccount.',
          'Under the "Membership & Billing" section, click the "Cancel Membership" button.',
          'Click "Finish Cancellation" to confirm. Your access remains active until the end of the current billing cycle.',
        ],
        supportEmail: 'support@netflix.com',
        emailTemplate:
            'Subject: Request for Subscription Cancellation\n\nDear Netflix Support,\n\nI am writing to formally request the immediate cancellation of my Netflix subscription associated with this email address. Please confirm that auto-renewal has been disabled.\n\nThank you.',
      );
    } else if (name.contains('adobe')) {
      return const CancellationGuide(
        merchant: 'Adobe Creative Cloud',
        directUrl: 'https://account.adobe.com/plans',
        steps: [
          'Go to account.adobe.com/plans and log in.',
          'Click "Manage plan" for the subscription you wish to cancel.',
          'Select "Cancel your plan" under Plan management and select your cancellation reason.',
          'Click "Continue" and verify that no early termination fees apply before finalizing.',
        ],
        supportEmail: 'support@adobe.com',
        emailTemplate:
            'Subject: Request to Cancel Adobe Subscription\n\nDear Adobe Support,\n\nI am requesting to cancel my Adobe Creative Cloud subscription. Please confirm that my membership is canceled and no further charges will be billed.\n\nThank you.',
      );
    } else if (name.contains('youtube') || name.contains('google')) {
      return const CancellationGuide(
        merchant: 'YouTube Premium',
        directUrl: 'https://www.youtube.com/paid_memberships',
        steps: [
          'Open youtube.com/paid_memberships in your browser.',
          'Click "Manage membership" next to YouTube Premium.',
          'Select "Deactivate" and then click "Continue to cancel".',
          'Select your reason and confirm by clicking "Yes, cancel".',
        ],
        supportEmail: 'support@google.com',
        emailTemplate:
            'Subject: YouTube Premium Cancellation Notice\n\nHi YouTube Team,\n\nPlease cancel my YouTube Premium membership immediately and confirm that auto-debit has been turned off.\n\nRegards.',
      );
    } else if (name.contains('spotify')) {
      return const CancellationGuide(
        merchant: 'Spotify Premium',
        directUrl: 'https://www.spotify.com/account/change-plan',
        steps: [
          'Log in at spotify.com/account/change-plan.',
          'Scroll down to "Cancel Spotify" and click "Cancel Premium".',
          'Follow the prompts until you reach the confirmation screen.',
        ],
        supportEmail: 'support@spotify.com',
        emailTemplate:
            'Subject: Spotify Premium Cancellation\n\nHi Spotify Team,\n\nI wish to cancel my Spotify Premium subscription. Please verify that future billing is canceled.\n\nThanks.',
      );
    } else if (name.contains('apple') || name.contains('icloud')) {
      return const CancellationGuide(
        merchant: 'Apple iCloud',
        directUrl: 'https://support.apple.com/HT207594',
        steps: [
          'On iPhone / Mac, open Settings → Tap your Name → "Subscriptions".',
          'Tap "iCloud+" or the targeted Apple subscription.',
          'Tap "Cancel Subscription" or "Downgrade Options" to select the free 5GB plan.',
        ],
        supportEmail: 'support@apple.com',
        emailTemplate:
            'Subject: Apple iCloud Storage Downgrade Request\n\nDear Apple Support,\n\nPlease downgrade my iCloud storage tier to the free plan and confirm no further auto-renewals will occur.\n\nThank you.',
      );
    } else if (name.contains('cult') || name.contains('fitness') || name.contains('gym')) {
      return const CancellationGuide(
        merchant: 'Cult.fit Pass',
        directUrl: 'https://www.cult.fit/me/subscriptions',
        steps: [
          'Open the Cult.fit App → Go to Profile → "Active Subscriptions".',
          'Select your Cultpass membership.',
          'Tap "Pause / Cancel Subscription" and follow the onscreen prompt.',
        ],
        supportEmail: 'hello@cult.fit',
        emailTemplate:
            'Subject: Cult.fit Pass Membership Cancellation\n\nDear Cult.fit Support,\n\nI would like to cancel my Cult.fit pass subscription. Please confirm that auto-debit has been cancelled.\n\nBest regards.',
      );
    }

    // Default fallback guide
    return CancellationGuide(
      merchant: merchantName,
      directUrl: 'https://www.google.com/search?q=how+to+cancel+$merchantName+subscription',
      steps: [
        'Log in to your account on $merchantName\'s official website or app.',
        'Navigate to Account Settings → Billing / Subscriptions.',
        'Locate active membership and select "Cancel Subscription" or "Turn off Auto-Renew".',
        'Check your email for a cancellation confirmation receipt.',
      ],
      supportEmail: 'support@${merchantName.toLowerCase().replaceAll(' ', '')}.com',
      emailTemplate:
          'Subject: Request to Cancel $merchantName Subscription\n\nDear $merchantName Support Team,\n\nI am writing to formally request the cancellation of my subscription. Please confirm that auto-renewal is disabled and no further charges will occur.\n\nThank you.',
    );
  }
}
