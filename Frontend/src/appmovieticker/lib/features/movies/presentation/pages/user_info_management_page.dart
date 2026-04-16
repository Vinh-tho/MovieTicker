import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/data/datasources/auth_local_datasource.dart';
import 'movies_page.dart';
import 'account_info_edit_page.dart';
import '../widgets/movie_menu_dialog.dart';

class UserInfoManagementPage extends StatefulWidget {
  const UserInfoManagementPage({super.key});

  @override
  State<UserInfoManagementPage> createState() => _UserInfoManagementPageState();
}

class _UserInfoManagementPageState extends State<UserInfoManagementPage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final local = di.sl<AuthLocalDataSource>();
    final token = await local.getToken();
    final profile = await local.getUserProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _isLoggedIn = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);
    final displayName =
        (_profile?['fullName']?.toString().trim().isNotEmpty ?? false)
        ? _profile!['fullName'].toString().trim()
        : 'Thành viên MTTB';
    final memberId = _profile?['id']?.toString() ?? '00000001';
    final avatarUrl =
        (_profile?['avatarUrl'] ?? _profile?['avatar'] ?? _profile?['imageUrl'])
            ?.toString()
            .trim();
    final hasAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty;
    final safeAvatarUrl = avatarUrl ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            4 * scale,
            4 * scale,
            4 * scale,
            4 * scale,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1.2),
            ),
            child: Column(
              children: [
                _Header(scale: scale),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            SizedBox(height: 8 * scale),
                            _ProfileSummary(
                              scale: scale,
                              displayName: displayName,
                              memberId: memberId,
                              hasAvatarUrl: hasAvatarUrl,
                              safeAvatarUrl: safeAvatarUrl,
                            ),
                            SizedBox(height: 8 * scale),
                            _InfoRow(
                              icon: Icons.list_alt_outlined,
                              label: 'Thông tin tài khoản',
                              scale: scale,
                              onTap: () async {
                                final shouldRefresh =
                                    await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AccountInfoEditPage(),
                                      ),
                                    );
                                if (shouldRefresh == true && mounted) {
                                  _loadProfile();
                                }
                              },
                            ),
                            _line(scale),
                            _InfoRow(
                              icon: Icons.lock_outline,
                              label: 'Thay đổi mật khẩu',
                              scale: scale,
                            ),
                            _line(scale),
                            _InfoRow(
                              icon: Icons.local_activity_outlined,
                              label: 'Voucher',
                              scale: scale,
                            ),
                            _line(scale),
                            SizedBox(height: 90 * scale),
                            Container(
                              height: 34 * scale,
                              width: double.infinity,
                              color: const Color(0xFFD6C35F),
                            ),
                            SizedBox(height: 26 * scale),
                            _InfoRow(
                              icon: Icons.history,
                              label: 'Lịch sử giao dịch',
                              scale: scale,
                            ),
                            _line(scale),
                            const Spacer(),
                            Container(
                              height: 34 * scale,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6C35F),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(26 * scale),
                                  bottomRight: Radius.circular(26 * scale),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(double scale) {
    return Container(height: 1, color: Colors.black26);
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 390).clamp(0.75, 0.95);
    }
    return 1;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54 * scale,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MoviesPage()),
                (route) => false,
              );
            },
            icon: Icon(
              Icons.arrow_back,
              color: const Color(0xFFEF4A4A),
              size: 24 * scale,
            ),
          ),
          Expanded(
            child: Text(
              'Thành viên MTTB',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17 * scale,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          IconButton(
            onPressed: () => showMovieMenuDialog(context, scale: scale),
            icon: Icon(
              Icons.menu,
              color: const Color(0xFFEF4A4A),
              size: 30 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.scale,
    required this.displayName,
    required this.memberId,
    required this.hasAvatarUrl,
    required this.safeAvatarUrl,
  });

  final double scale;
  final String displayName;
  final String memberId;
  final bool hasAvatarUrl;
  final String safeAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 92 * scale,
          height: 92 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipOval(
                  child: hasAvatarUrl
                      ? Image.network(
                          safeAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Image.asset(
                            'assets/images/avatramacdinh.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/avatramacdinh.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                right: 4 * scale,
                top: 34 * scale,
                child: Container(
                  width: 20 * scale,
                  height: 20 * scale,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                  child: Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 12 * scale,
                  ),
                ),
              ),
              Positioned(
                right: -5 * scale,
                bottom: 8 * scale,
                child: Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EAD1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          displayName,
          style: TextStyle(
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6 * scale),
        Text(
          'ID :',
          style: TextStyle(
            fontSize: 11 * scale,
            color: Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          memberId,
          style: TextStyle(
            fontSize: 21 * scale,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          'Tổng chi tiêu 2026',
          style: TextStyle(
            fontSize: 12 * scale,
            color: Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(
          _buildSpendingText(),
          style: TextStyle(
            fontSize: 29 * scale,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _buildSpendingText() {
    return '200000 đ';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.scale,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44 * scale,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: 21 * scale),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.black, size: 30 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
