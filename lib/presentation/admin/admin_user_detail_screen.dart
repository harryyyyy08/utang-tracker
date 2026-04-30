import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/admin_repository.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final ProfileModel user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _repo = AdminRepository();
  bool _loading = false;
  late ProfileModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _refresh() async {
    final users = await _repo.getAllUsers();
    final updated = users.where((u) => u.id == _user.id).firstOrNull;
    if (updated != null && mounted) setState(() => _user = updated);
  }

  Future<void> _runAction(Future<void> Function() action, String successMessage) async {
    setState(() => _loading = true);
    try {
      await action();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Shows a confirmation dialog. Returns true if confirmed.
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = Colors.blue,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huwag'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  String get _displayName => _user.storeName ?? _user.ownerName ?? 'user';

  Future<void> _onActivate() async {
    final hasUnpaidReferral =
        _user.referredBy != null && !_user.referralRewardPaid;
    final ok = await _confirm(
      title: 'I-activate ang Subscription?',
      message: hasUnpaidReferral
          ? 'Si $_displayName ay may referral reward na hindi pa nabibigay.\n\n'
              '• Siya ay makakakuha ng 60 araw (2 buwan) na subscription.\n'
              '• Ang nag-refer sa kanya ay makakakuha ng +1 libreng buwan.\n\n'
              'Awtomatiko itong malalapat.'
          : 'Magiging active si $_displayName ng 30 araw mula ngayon.',
      confirmLabel: 'I-activate',
      confirmColor: Colors.green,
    );
    if (ok) {
      _runAction(
        () => _repo.activateSubscription(_user.id),
        'Na-activate na ang subscription!',
      );
    }
  }

  Future<void> _onExtend(int months) async {
    final ok = await _confirm(
      title: 'I-extend ng $months ${months == 1 ? "buwan" : "buwan"}?',
      message:
          'Madadagdagan ng $months ${months == 1 ? "buwan" : "buwan"} ang subscription ni $_displayName '
          'base sa kasalukuyang expiry date niya.',
      confirmLabel: 'I-extend',
      confirmColor: Colors.blue,
    );
    if (ok) {
      _runAction(
        () => _repo.extendSubscription(_user.id, months),
        'Na-extend na ng $months ${months == 1 ? "buwan" : "buwan"}!',
      );
    }
  }

  Future<void> _onDeactivate() async {
    final isTrial = _user.subscriptionStatus == 'trial';
    final expiry = _user.subscriptionExpiry;
    final hasTrialLeft = isTrial &&
        expiry != null &&
        expiry.toUtc().isAfter(DateTime.now().toUtc());

    final ok = await _confirm(
      title: 'I-expire ang Account?',
      message: hasTrialLeft
          ? 'Si $_displayName ay nasa free trial pa (${_formatExpiry(expiry)}). '
              'Kapag na-expire, hindi na sila makapag-login. '
              'Gamitin ang "Restore to Trial" para ibalik ang trial nila.'
          : 'Hindi na makapag-login si $_displayName hanggang ma-activate ulit ang kanyang account.',
      confirmLabel: 'I-expire',
      confirmColor: Colors.red,
    );
    if (ok) {
      _runAction(
        () => _repo.deactivateSubscription(_user.id),
        'Na-expire na ang account.',
      );
    }
  }

  Future<void> _onRestoreToTrial() async {
    final ok = await _confirm(
      title: 'I-restore sa Free Trial?',
      message:
          'Ibabalik ang free trial ni $_displayName. '
          'Ang expiry ay base sa original na signup date (14 days). '
          'Kung lumipas na ang trial period, bibigyan siya ng 14 bagong araw.',
      confirmLabel: 'I-restore',
      confirmColor: Colors.orange,
    );
    if (ok) {
      _runAction(
        () => _repo.restoreToTrial(_user.id),
        'Na-restore na sa free trial!',
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'trial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'trial':
        return 'Free Trial';
      default:
        return 'Expired';
    }
  }

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return 'Walang expiry';
    return DateFormat('MMM d, yyyy').format(expiry.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(_user.subscriptionStatus);
    final expiry = _user.subscriptionExpiry;
    final expiryText = expiry != null
        ? DateFormat('MMMM d, yyyy – hh:mm a').format(expiry.toLocal())
        : 'Walang expiry date';

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(Icons.store, size: 36, color: color),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _user.storeName ?? '(Walang store name)',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (_user.ownerName != null)
                            Text(_user.ownerName!,
                                style: const TextStyle(color: Colors.grey)),
                          if (_user.phone != null)
                            Text(_user.phone!,
                                style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(_user.subscriptionStatus),
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(expiryText,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          if (_user.referredBy != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _user.referralRewardPaid
                                    ? Colors.grey[100]
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _user.referralRewardPaid
                                      ? Colors.grey[300]!
                                      : Colors.green,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _user.referralRewardPaid
                                        ? Icons.card_giftcard
                                        : Icons.card_giftcard_outlined,
                                    size: 14,
                                    color: _user.referralRewardPaid
                                        ? Colors.grey
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _user.referralRewardPaid
                                        ? 'Referral reward: Nabayaran na ✓'
                                        : 'Referral reward: Pending (sa first subscription)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _user.referralRewardPaid
                                          ? Colors.grey
                                          : Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Manage Subscription',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Activate (30 days mula ngayon)',
                    color: Colors.green,
                    onTap: _onActivate,
                  ),
                  const SizedBox(height: 8),

                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Extend +1 buwan',
                    color: Colors.blue,
                    onTap: () => _onExtend(1),
                  ),
                  const SizedBox(height: 8),

                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Extend +3 buwan',
                    color: Colors.indigo,
                    onTap: () => _onExtend(3),
                  ),
                  const SizedBox(height: 8),

                  _ActionButton(
                    icon: Icons.history,
                    label: 'Restore to Free Trial',
                    color: Colors.orange,
                    onTap: _onRestoreToTrial,
                  ),
                  const SizedBox(height: 8),

                  _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'I-expire ang Account',
                    color: Colors.red,
                    onTap: _onDeactivate,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onTap,
      ),
    );
  }
}
