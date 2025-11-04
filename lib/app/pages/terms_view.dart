import 'package:flutter/material.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
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
              const _TermsSection(
                title: '1. Acceptance of Terms',
                content: '''
          By accessing and using Sonus Music ("the Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.
              ''',
              ),
              const _TermsSection(
                title: '2. Description of Service',
                content: '''
          Sonus Music is a music playing service that provides users with access to a vast library of music content. Our service includes:
          
          • Playing of music content
          • Personalized playlists and recommendations
          • Offline listening capabilities
          
          We reserve the right to modify, suspend, or discontinue any aspect of the service at any time.
              ''',
              ),
              const _TermsSection(
                title: '3. User Accounts',
                content: '''
          To use our service, you can create an account. You agree to:
          
          • Provide accurate and complete information
          • Maintain the security of your password
          • Accept responsibility for all activities under your account
          • Notify us immediately of any unauthorized use
          • Be at least 13 years old to create an account
          
          We reserve the right to terminate accounts that violate these terms.
              ''',
              ),
              const _TermsSection(
                title: '4. Acceptable Use',
                content: '''
          You agree not to:
          
          • Use the service for any unlawful purpose
          • Attempt to gain unauthorized access to our systems
          • Interfere with or disrupt the service
          • Reverse engineer or attempt to extract source code
          • Use automated means to access the service
          • Share your account credentials with others
          • Violate any applicable laws or regulations
              ''',
              ),
              const _TermsSection(
                title: '5. Intellectual Property',
                content: '''
          The service and its original content, features, and functionality are owned by Sonus Music and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.
          
          • You may not reproduce, distribute, or create derivative works
          • All music content is licensed from third-party rights holders
          • Unauthorized use may result in legal action
          • We respect the intellectual property rights of others
              ''',
              ),
              //           const _TermsSection(
              //             title: '6. Payment and Billing',
              //             content: '''
              // For paid services:

              // • Subscription fees are billed in advance
              // • All fees are non-refundable unless otherwise stated
              // • We may change pricing with 30 days notice
              // • You can cancel your subscription at any time
              // • Refunds are handled on a case-by-case basis
              // • We accept major credit cards and other payment methods
              //             ''',
              //           ),
              const _TermsSection(
                title: '6. Privacy and Data',
                content: '''
          Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the service, to understand our practices.
          
          • We collect and use data as described in our Privacy Policy
          • You have rights regarding your personal data
          • We implement appropriate security measures
          • Data may be processed in different countries
              ''',
              ),
              const _TermsSection(
                title: '7. Disclaimers and Limitations',
                content: '''
          The service is provided "as is" without warranties of any kind. We disclaim all warranties, express or implied, including:
          
          • Merchantability and fitness for a particular purpose
          • Non-infringement of third-party rights
          • Uninterrupted or error-free service
          • Security of data transmission
          
          Our liability is limited to the maximum extent permitted by law.
              ''',
              ),
              const _TermsSection(
                title: '8. Termination',
                content: '''
          We may terminate or suspend your account immediately, without prior notice, for conduct that we believe violates these terms or is harmful to other users, us, or third parties.
          
          • You may terminate your account at any time
          • Upon termination, your right to use the service ceases
          • We may retain certain information as required by law
          • Outstanding payments remain due after termination
              ''',
              ),
              const _TermsSection(
                title: '9. Changes to Terms',
                content: '''
          We reserve the right to modify these terms at any time. We will notify users of significant changes by:
          
          • Posting the updated terms on our website
          • Sending email notifications to registered users
          • Displaying notices within the application
          
          Continued use of the service after changes constitutes acceptance of the new terms.
              ''',
              ),
              const _TermsSection(
                title: '10. Governing Law',
                content: '''
          These terms shall be governed by and construed in accordance with the laws of Myanmar, without regard to conflict of law principles.
          
          Any disputes arising from these terms or the service shall be resolved through binding arbitration in accordance with the rules of the Myanmar Arbitration Association.
              ''',
              ),
              const _TermsSection(
                title: '11. Contact Information',
                content: '''
          If you have any questions about these Terms of Service, please contact us at:
          
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

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({
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
