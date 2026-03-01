import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/link_model.dart';

class LinkCard extends StatelessWidget {
  final LinkModel link;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LinkCard({
    super.key,
    required this.link,
    this.onEdit,
    this.onTap,
    this.onDelete,
  });

  Future<void> _openLink() async {
    final url = link.url.startsWith('http') ? link.url : 'https://${link.url}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          onTap?.call();
          _openLink();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      link.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: link.isRead
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // URL/Domain
                    Text(
                      link.domain,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Bottom row: date, label, read status
                    Row(
                      children: [
                        // Date
                        Text(
                          link.createdAt.relativeTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),

                        // Label chip
                        if (link.label != null && link.label!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              link.label!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Read indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: link.isRead
                                ? AppColors.readIndicator
                                : AppColors.unreadIndicator,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit button
              if (onEdit != null)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: link.thumbnailUrl != null && link.thumbnailUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: link.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.link,
                color: AppColors.onSurfaceVariant,
                size: 32,
              ),
            )
          : const Icon(
              Icons.link,
              color: AppColors.onSurfaceVariant,
              size: 32,
            ),
    );
  }
}
