import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_core/flutter_core.dart';

/// Reusable professional card widget
class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback? onTap;
  final bool showBookButton;

  const ProfessionalCard({
    super.key,
    required this.professional,
    this.onTap,
    this.showBookButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Professional photo
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: professional.photoUrl != null
                        ? CachedNetworkImageProvider(professional.photoUrl!)
                        : null,
                    child: professional.photoUrl == null
                        ? Text(
                            professional.firstName[0] +
                                professional.lastName[0],
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Professional info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                professional.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (professional.isVerified)
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          professional.specialty.displayName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${professional.rating.toStringAsFixed(1)} (${professional.reviewCount})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${professional.yearsOfExperience} años exp.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bio (if available)
              if (professional.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  professional.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],

              // Fee and availability
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (professional.consultationFee != null)
                    Chip(
                      label: Text(
                        '\$${professional.consultationFee!.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      avatar: const Icon(Icons.attach_money, size: 18),
                      backgroundColor: Colors.green.shade50,
                    ),
                  if (showBookButton)
                    FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Agendar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
