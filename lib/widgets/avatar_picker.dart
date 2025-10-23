import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarPicker extends StatelessWidget {
  // This function will be called with the selected style name
  final Function(String) onAvatarSelected;

  const AvatarPicker({super.key, required this.onAvatarSelected});

  @override
  Widget build(BuildContext context) {
    // A map of user-friendly names to the style names used by the API
    final avatarStyles = {
      'Initials': 'initials',
      'Adventurer': 'adventurer',
      'Pixel Art': 'pixel-art',
      'Bottts': 'bottts',
      'Avataaars': 'avataaars',
      'Miniavs': 'miniavs',
      'Open Peeps': 'open-peeps',
      'Personas': 'personas',
    };

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Chat Avatar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: avatarStyles.length,
            itemBuilder: (context, index) {
              final styleName = avatarStyles.keys.elementAt(index);
              final styleValue = avatarStyles.values.elementAt(index);

              // Use a placeholder seed to generate a preview of the style
              final previewUrl = 'https://api.dicebear.com/8.x/$styleValue/svg?seed=preview';

              return GestureDetector(
                onTap: () {
                  onAvatarSelected(styleValue); // Send the selected style back
                  Navigator.pop(context);      // Close the bottom sheet
                },
                child: Column(
                  children: [
                    Expanded(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: ClipOval(
                          child: SvgPicture.network(
                            previewUrl,
                            placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(styleName, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}