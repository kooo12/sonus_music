import 'package:flutter/material.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: TpsSizes.defaultSpace * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: January 2025',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 40),
              const _PrivacySection(
                title: '1. Information We Collect',
                content: '''
          We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support. This may include:
          
          • Account information (name, email address)
          • Profile information (music preferences, playlists, listening history)
          • Communications with us (support requests, feedback)
          • Usage information (how you interact with our app)
              ''',
              ),
              const _PrivacySection(
                title: '2. How We Use Your Information',
                content: '''
          We use the information we collect to:
          
          • Provide, maintain, and improve our services
          • Process transactions and send related information
          • Send technical notices, updates, and support messages
          • Respond to your comments and questions
          • Personalize your music experience
          • Monitor and analyze trends and usage
          • Detect, investigate, and prevent security incidents
              ''',
              ),
              const _PrivacySection(
                title: '3. Information Sharing',
                content: '''
          We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except:
          
          • With service providers who assist us in operating our app
          • When required by law or to protect our rights
          • In connection with a merger, acquisition, or sale of assets
          • With your explicit consent
              ''',
              ),
              const _PrivacySection(
                title: '4. Data Security',
                content: '''
          We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.
          
          • We use encryption to protect sensitive information
          • We regularly review our security practices
          • We limit access to personal information to authorized personnel
          • We maintain secure data centers with physical and digital safeguards
              ''',
              ),
              const _PrivacySection(
                title: '5. Your Rights',
                content: '''
          You have the right to:
          
          • Access your personal information
          • Correct inaccurate or incomplete information
          • Delete your personal information
          • Object to processing of your personal information
          • Data portability
          
          To exercise these rights, please contact us at aungkooo1210@gmail.com
              ''',
              ),
              const _PrivacySection(
                title: '6. Cookies and Tracking',
                content: '''
          We use cookies and similar technologies to:
          
          • Remember your preferences and settings
          • Analyze how you use our app
          • Provide personalized content and advertisements
          • Improve our services
          
          You can control cookie settings through your browser preferences.
              ''',
              ),
              const _PrivacySection(
                title: '7. Children\'s Privacy',
                content: '''
          Our services are not intended for children under 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information.
              ''',
              ),
              const _PrivacySection(
                title: '8. Changes to This Policy',
                content: '''
          We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. We encourage you to review this Privacy Policy periodically for any changes.
              ''',
              ),
              const _PrivacySection(
                title: '9. Contact Us',
                content: '''
          If you have any questions about this Privacy Policy, please contact us at:
          
          Email: agkooo.ako36@gmail.com
          Phone: +959 761 190 037
          
          We will respond to your inquiries within 48 hours.
              ''',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String content;

  const _PrivacySection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
