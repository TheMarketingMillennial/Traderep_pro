import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../core/theme/app_theme.dart';

// ─── TradeRep Logo Widget ─────────────────────────────────────────────────────
class TRLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool horizontal;

  const TRLogo({super.key, this.size = 80, this.showTagline = false, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    Widget logoMark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TRColors.navyMid,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: TRColors.divider, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner brackets
          Positioned(top: size*0.08, left: size*0.08,
            child: _CornerBracket(size: size*0.22, topLeft: true)),
          Positioned(top: size*0.08, right: size*0.08,
            child: _CornerBracket(size: size*0.22, topRight: true)),
          Positioned(bottom: size*0.08, left: size*0.08,
            child: _CornerBracket(size: size*0.22, bottomLeft: true)),
          Positioned(bottom: size*0.08, right: size*0.08,
            child: _CornerBracket(size: size*0.22, bottomRight: true)),
          // TR Monogram
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('T', style: TextStyle(
                color: TRColors.white,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -2,
              )),
              Text('R', style: TextStyle(
                color: TRColors.gold,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -2,
              )),
            ],
          ),
          // Checkmark accent
          Positioned(
            bottom: size * 0.12,
            right: size * 0.18,
            child: Icon(Icons.check_rounded, color: TRColors.gold, size: size * 0.18),
          ),
        ],
      ),
    );

    Widget wordmark = Column(
      crossAxisAlignment: horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'Trade', style: TextStyle(
                color: TRColors.white,
                fontSize: size * 0.28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              )),
              TextSpan(text: 'Rep', style: TextStyle(
                color: TRColors.gold,
                fontSize: size * 0.28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              )),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Container(width: size * 0.5, height: 1.5, color: TRColors.gold),
          const SizedBox(height: 4),
          Text(
            'PROOF.  VISIBILITY.  GROWTH.',
            style: TextStyle(
              color: TRColors.grayLight,
              fontSize: size * 0.1,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoMark,
          SizedBox(width: size * 0.18),
          wordmark,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoMark,
        SizedBox(height: size * 0.14),
        wordmark,
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final double size;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  const _CornerBracket({
    required this.size,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BracketPainter(
        topLeft: topLeft, topRight: topRight,
        bottomLeft: bottomLeft, bottomRight: bottomRight,
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _BracketPainter({
    this.topLeft = false, this.topRight = false,
    this.bottomLeft = false, this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TRColors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    if (topLeft) {
      canvas.drawLine(Offset(0, s * 0.6), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(s * 0.6, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(s * 0.4, 0), Offset(s, 0), paint);
      canvas.drawLine(Offset(s, 0), Offset(s, s * 0.6), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, s * 0.4), Offset(0, s), paint);
      canvas.drawLine(Offset(0, s), Offset(s * 0.6, s), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(s * 0.4, s), Offset(s, s), paint);
      canvas.drawLine(Offset(s, s), Offset(s, s * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class TRStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? trend;
  final VoidCallback? onTap;

  const TRStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? TRColors.gold;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TRColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap != null
                  ? color.withValues(alpha: 0.25)
                  : TRColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TRColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(trend!, style: const TextStyle(
                        color: TRColors.success, fontSize: 11, fontWeight: FontWeight.w600,
                      )),
                    )
                  else if (onTap != null)
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: color.withValues(alpha: 0.5), size: 12),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(
                color: TRColors.white, fontSize: 26, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(
                color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final JobStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = JobStatusTheme.color(status.displayName);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Job Card ─────────────────────────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TRColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TRColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.customerName,
                    style: const TextStyle(
                      color: TRColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: job.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              job.jobType,
              style: const TextStyle(
                color: TRColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: TRColors.grayMid, size: 13),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    job.address,
                    style: const TextStyle(color: TRColors.grayMid, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (job.startDate != null) ...[
                  const Icon(Icons.calendar_today_rounded, color: TRColors.grayMid, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(job.startDate!),
                    style: const TextStyle(color: TRColors.grayLight, fontSize: 12),
                  ),
                  const Spacer(),
                ],
                const Icon(Icons.photo_library_outlined, color: TRColors.grayMid, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${job.photos.length} photos',
                  style: const TextStyle(color: TRColors.grayLight, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(
                  job.reviewSent ? Icons.mark_email_read_outlined : Icons.reviews_outlined,
                  color: job.reviewSent ? TRColors.success : TRColors.grayMid,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  job.reviewSent ? 'Review sent' : 'No review',
                  style: TextStyle(
                    color: job.reviewSent ? TRColors.success : TRColors.grayMid,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(
          color: TRColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        )),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(action!, style: const TextStyle(
              color: TRColors.gold, fontSize: 13, fontWeight: FontWeight.w600,
            )),
          ),
      ],
    );
  }
}

// ─── Gold Action Button ───────────────────────────────────────────────────────
class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;
  final bool compact;

  const GoldButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.outlined = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 44 : 54,
      child: outlined
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: TRColors.gold,
              side: const BorderSide(color: TRColors.gold, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: icon != null ? Icon(icon, size: 18, color: TRColors.navyDeep) : const SizedBox.shrink(),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: TRColors.gold,
              foregroundColor: TRColors.navyDeep,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class TREmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TREmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TRColors.cardMid,
                shape: BoxShape.circle,
                border: Border.all(color: TRColors.divider),
              ),
              child: Icon(icon, color: TRColors.grayLight, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(
              color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w700,
            ), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(
              color: TRColors.grayMid, fontSize: 14,
            ), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GoldButton(label: actionLabel!, onTap: onAction, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case UserRole.admin:         return TRColors.gold;
      case UserRole.officeManager: return TRColors.info;
      case UserRole.salesRep:      return TRColors.statusLead;
      case UserRole.crewLead:      return TRColors.statusInProgress;
      case UserRole.crewMember:    return TRColors.grayLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, color: _color, size: 11),
          const SizedBox(width: 4),
          Text(role.displayName, style: TextStyle(
            color: _color, fontSize: 11, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

// ─── Photo Score Indicator ────────────────────────────────────────────────────
class PhotoScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color? color;

  const PhotoScoreBar({super.key, required this.label, required this.score, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? TRColors.gold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: TRColors.grayLight, fontSize: 12)),
            Text('${(score * 10).round()}/10', style: TextStyle(
              color: c, fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: TRColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(c),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
