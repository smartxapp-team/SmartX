import 'package:flutter/material.dart';
import 'skeleton.dart';

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Fixed Header Skeleton
        Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            children: [
              Skeleton(height: 48, width: double.infinity),
              SizedBox(height: 16),
              SizedBox(
                height: 75,
                child: Row(
                  children: [
                    Expanded(child: Skeleton()),
                    SizedBox(width: 10),
                    Expanded(child: Skeleton()),
                    SizedBox(width: 10),
                    Expanded(child: Skeleton()),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Body Skeleton
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Skeleton(height: 150)),
                    SizedBox(width: 8),
                    Expanded(child: Skeleton(height: 150)),
                  ],
                ),
                SizedBox(height: 24),
                Skeleton(height: 120),
                SizedBox(height: 24),
                Skeleton(height: 90),
              ],
            ),
          ),
        ),
      ],
    );
  }
}