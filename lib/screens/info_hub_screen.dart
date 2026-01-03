import 'package:flutter/material.dart';
import '../theme.dart';

class InfoHubScreen extends StatelessWidget {
  const InfoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Information Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300], // Placeholder for image
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://placehold.co/600x400/png'),
                  // Placeholder
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Safety Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Safety First: Verify Before You Use',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Did you know counterfeit drugs pose a significant risk to public health? Always verify the FDA seal.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Signs of Counterfeits
            const Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.warningRed),
                SizedBox(width: 8),
                Text(
                  'Signs of Counterfeits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.inventory_2,
              title: 'Check Packaging',
              description:
                  'Look for breaks in the seal, unusual fonts, or faded colors on the box.',
              color: Colors.red[50]!,
              iconColor: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              icon: Icons.spellcheck,
              title: 'Verify Spelling',
              description:
                  'Counterfeit drugs often have misspellings of common medical terms.',
              color: Colors.orange[50]!,
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              icon: Icons.verified_user,
              title: 'Inspect the Seal',
              description:
                  'Ensure the security seal is intact and matches the manufacturer standard.',
              color: Colors.blue[50]!,
              iconColor: Colors.blue,
            ),

            const SizedBox(height: 32),

            // How to Report
            const Text(
              'How to Report Suspicious Drugs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStep(context, '1', Icons.do_not_touch, 'Do not use'),
                Container(width: 30, height: 1, color: Colors.grey[300]),
                _buildStep(context, '2', Icons.camera_alt, 'Take Photo'),
                Container(width: 30, height: 1, color: Colors.grey[300]),
                _buildStep(context, '3', Icons.send, 'Submit', isActive: true),
              ],
            ),

            const SizedBox(height: 32),

            // FAQ
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'What if the barcode won\'t scan?',
              'Try cleaning your camera lens or moving to a brighter area.',
            ),
            _buildFAQItem(
              'Is this app official?',
              'Yes, this app is powered by the FDA Ghana.',
            ),
            _buildFAQItem(
              'How do I verify the batch number?',
              'The batch number is automatically verified when you scan the barcode.',
            ),

            const SizedBox(height: 32),

            // Contact
            const Text(
              'Contact FDA Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildContactButton(Icons.phone, 'Helpline')),
                const SizedBox(width: 16),
                Expanded(child: _buildContactButton(Icons.email, 'Email Us')),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/scanner');
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Drug Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    IconData icon,
    String label, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primaryGreen : Colors.grey[300]!,
            ),
          ),
          child: Icon(icon, color: isActive ? Colors.black : Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          '$number. $label',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(answer, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
