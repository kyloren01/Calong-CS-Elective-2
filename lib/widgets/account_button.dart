import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/app_user.dart';
import '../state/auth_cubit.dart';
import '../theme/app_theme.dart';

/// The signed-in person's picture. Tapping it shows who is signed in, how,
/// and a Sign out option.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit cubit) => cubit.state.user);
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: (_) => context.read<AuthCubit>().signOut(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (user.email case final email? when email != user.displayName)
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (user.provider == 'github')
                    FaIcon(FontAwesomeIcons.github, size: 14, color: muted)
                  else
                    Icon(Icons.mail_outline_rounded, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Signed in with ${user.providerLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'sign-out',
          child: Row(
            children: [
              Icon(Icons.logout_rounded),
              SizedBox(width: 12),
              Text('Sign out'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: UserAvatar(user: user),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 16});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    final name = user.displayName;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      backgroundImage: url == null ? null : NetworkImage(url),
      // A missing picture (or no internet) just leaves the orange circle.
      onBackgroundImageError: url == null ? null : (_, _) {},
      child: url == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            )
          : null,
    );
  }
}
