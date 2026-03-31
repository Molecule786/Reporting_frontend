import 'package:flutter/material.dart';
import '../utils/language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  final LanguageProvider languageProvider;

  const LanguageSwitcher({super.key, required this.languageProvider});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageProvider.locale.languageCode == 'en' ? 'EN' : 'اردو',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.language, size: 20),
        ],
      ),
      onPressed: () {
        languageProvider.toggleLanguage();
      },
      tooltip: languageProvider.locale.languageCode == 'en' 
          ? 'Switch to Urdu' 
          : 'انگریزی میں تبدیل کریں',
    );
  }
}
