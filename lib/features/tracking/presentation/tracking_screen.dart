import 'package:erp_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _TrackingHeroCard(),

            const SizedBox(height: 16),

            const _ShipmentProgressCard(),

            const SizedBox(height: 16),

            _InfoCard(
              child: Row(
                children: [
                  const _CircleIcon(icon: Icons.location_on_rounded),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Near Surat, Gujarat, India',
                          style: TextStyle(color: AppColors.text, fontSize: 15),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Aug 22, 11:40 AM',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/claim_reward_screen');
                    },
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 17),
                    label: const Text('Live Tracking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const _DeliveryDetailsCard(),

            const SizedBox(height: 16),

            _InfoCard(
              child: Row(
                children: [
                  const _CircleIcon(icon: Icons.headset_mic_rounded),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Contact our support team for any assistance.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TrackingHeroCard extends StatelessWidget {
  const _TrackingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.local_shipping_rounded,
              size: 95,
              color: Colors.white.withOpacity(.20),
            ),
          ),
          Positioned(
            right: 20,
            top: 8,
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order ID',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                '#TRK85296314',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'In Transit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShipmentProgressCard extends StatelessWidget {
  const _ShipmentProgressCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _CircleIcon(icon: Icons.inventory_2_outlined, small: true),
              SizedBox(width: 10),
              Text(
                'Shipment Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: const [
              _ProgressStep(
                title: 'Order\nConfirmed',
                subtitle: 'Aug 20, 10:30 AM',
                completed: true,
              ),
              _ProgressLine(active: true),
              _ProgressStep(
                title: 'Picked Up',
                subtitle: 'Aug 21, 09:15 AM',
                completed: true,
              ),
              _ProgressLine(active: true),
              _ProgressStep(
                title: 'In Transit',
                subtitle: 'Aug 22, 11:40 AM',
                active: true,
              ),
              _ProgressLine(),
              _ProgressStep(title: 'Delivered', subtitle: 'Pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final bool active;

  const _ProgressStep({
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.border;

    if (completed || active) {
      color = AppColors.accent;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: completed ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 19)
                : active
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.primary : AppColors.text,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final bool active;

  const _ProgressLine({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 3,
      margin: const EdgeInsets.only(bottom: 55),
      color: active ? AppColors.accent : AppColors.border,
    );
  }
}

class _DeliveryDetailsCard extends StatelessWidget {
  const _DeliveryDetailsCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),

          const _DetailRow(
            icon: Icons.calendar_month_rounded,
            title: 'Estimated Delivery',
            value: 'Aug 24, 2026\nBefore 8:00 PM',
          ),

          const Divider(color: AppColors.border),

          const _DetailRow(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery Partner',
            value: 'BlueDart Express',
          ),

          const Divider(color: AppColors.border),

          const _DetailRow(
            icon: Icons.shield_outlined,
            title: 'Tracking Number',
            value: 'BD123456789IN',
            showCopy: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool showCopy;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.showCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _CircleIcon(icon: icon, small: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (showCopy) ...[
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded, size: 17, color: AppColors.muted),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final bool small;

  const _CircleIcon({required this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: small ? 19 : 24),
    );
  }
}
