import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Help & Support View built using StatelessWidget and GetX
class HelpAndSupportView extends StatelessWidget {
  const HelpAndSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF041C16), size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SupportHeaderCard(),
                  SizedBox(height: 24),
                  _QuickContactCardsSection(),
                  SizedBox(height: 24),
                  _FaqSection(),
                  SizedBox(height: 24),
                  _ContactUsFormSection(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Support Header Card Banner (Stateless)
class _SupportHeaderCard extends StatelessWidget {
  const _SupportHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF041C16),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A041C16),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE0D3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: Color(0xFF041C16),
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E463C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E6356)),
                ),
                child: Text(
                  'Partner Desk Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEFE0D3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'How can we help you?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our dedicated partner assistance team is here to support your salon business 7 days a week.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFB0C4BE),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Contact Action Cards (Stateless)
class _QuickContactCardsSection extends StatelessWidget {
  const _QuickContactCardsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Support',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ContactOptionCard(
                icon: Icons.phone_in_talk_rounded,
                title: 'Call Support',
                subtitle: '+91 1800-123-4567',
                onTap: () {
                  Get.snackbar(
                    'Call Support',
                    'Calling Book\'N\'Glow Partner Helpline: 1800-123-4567',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF041C16),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContactOptionCard(
                icon: Icons.email_outlined,
                title: 'Email Us',
                subtitle: 'support@booknglow.com',
                onTap: () {
                  Get.snackbar(
                    'Email Support',
                    'Opening email client for support@booknglow.com',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF041C16),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual Contact Option Card Widget (Stateless)
class _ContactOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF041C16)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frequently Asked Questions Section (Stateless)
class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I update my salon details and photo?',
        'a': 'Go to your Profile tab and tap on "Salon Details". You can edit your shop image, business name, owner name, contact phone number, and operating hours.',
      },
      {
        'q': 'How do I manage my services menu & pricing?',
        'a': 'Navigate to the "Services" tab from the bottom menu. You can add new treatments, update prices, or remove existing offerings anytime.',
      },
      {
        'q': 'When are booking payments disbursed to my account?',
        'a': 'Payouts are automatically processed to your registered bank account on a weekly basis every Monday for all completed appointments.',
      },
      {
        'q': 'What should I do if a client does not show up?',
        'a': 'In the Bookings tab, locate the appointment and update the status to "Cancelled". This updates your queue and notifies customer support.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: faqs.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == faqs.length - 1;

              return Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      title: Text(
                        item['q']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      iconColor: const Color(0xFF041C16),
                      collapsedIconColor: const Color(0xFF6B7280),
                      children: [
                        Text(
                          item['a']!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4B5563),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Send Us a Message Form Section (Stateless UI)
class _ContactUsFormSection extends StatelessWidget {
  const _ContactUsFormSection();

  @override
  Widget build(BuildContext context) {
    final TextEditingController messageController = TextEditingController();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, size: 18, color: Color(0xFF041C16)),
              const SizedBox(width: 8),
              Text(
                'Submit Support Ticket',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Need help with something specific? Send your query directly to our support desk.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: messageController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1F2937)),
            decoration: InputDecoration(
              hintText: 'Describe your question or issue in detail...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF041C16), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                messageController.clear();
                Get.snackbar(
                  'Ticket Submitted',
                  'Thank you! Our support team will get back to you shortly.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF041C16),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF041C16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SUBMIT TICKET',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
