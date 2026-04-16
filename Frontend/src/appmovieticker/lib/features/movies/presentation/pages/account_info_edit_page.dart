import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/data/datasources/user_profile_remote_datasource.dart';

class AccountInfoEditPage extends StatefulWidget {
  const AccountInfoEditPage({super.key});

  @override
  State<AccountInfoEditPage> createState() => _AccountInfoEditPageState();
}

class _AccountInfoEditPageState extends State<AccountInfoEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _gender;
  DateTime? _dateOfBirth;
  int? _cachedAccountId;
  int? _cachedId;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    final local = di.sl<AuthLocalDataSource>();
    final remote = di.sl<UserProfileRemoteDataSource>();

    final localProfile = await local.getUserProfile();
    Map<String, dynamic>? remoteProfile;
    try {
      remoteProfile = await remote.getProfile();
    } catch (_) {}

    final profile = remoteProfile ?? localProfile ?? <String, dynamic>{};
    await _cacheProfile(local, profile, fallback: localProfile);

    _fullNameController.text = profile['fullName']?.toString() ?? '';
    _emailController.text = profile['email']?.toString() ?? '';
    _phoneController.text = profile['phone']?.toString() ?? '';
    _addressController.text = profile['address']?.toString() ?? '';
    _gender = profile['gender']?.toString();
    _dateOfBirth = _tryParseDate(profile['dateOfBirth']?.toString());
    _cachedAccountId = _toInt(profile['accountId']) ?? _toInt(profile['id']);
    _cachedId = _toInt(profile['userId']) ?? _toInt(profile['id']);
    _avatarUrl = profile['avatarUrl']?.toString();

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final remote = di.sl<UserProfileRemoteDataSource>();
    final local = di.sl<AuthLocalDataSource>();

    try {
      final updated = await remote.updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _gender,
        dateOfBirth: _dateOfBirth == null ? null : _formatDate(_dateOfBirth!),
        address: _addressController.text.trim(),
      );

      await _cacheProfile(
        local,
        updated,
        fallback: await local.getUserProfile(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin tài khoản')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _dateOfBirth = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _uiScale(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8 * scale,
            8 * scale,
            8 * scale,
            8 * scale,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 1.2),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 56 * scale,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFEF4A4A),
                          size: 24 * scale,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17 * scale,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            14 * scale,
                            8 * scale,
                            14 * scale,
                            16 * scale,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Họ và tên', scale),
                                _buildTextField(
                                  controller: _fullNameController,
                                  scale: scale,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 12 * scale),
                                _buildLabel('Email (chưa hỗ trợ đổi)', scale),
                                _buildTextField(
                                  controller: _emailController,
                                  scale: scale,
                                  readOnly: true,
                                ),
                                SizedBox(height: 12 * scale),
                                _buildLabel('Số điện thoại', scale),
                                _buildTextField(
                                  controller: _phoneController,
                                  scale: scale,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập số điện thoại';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 12 * scale),
                                _buildLabel('Giới tính', scale),
                                Container(
                                  height: 46 * scale,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      12 * scale,
                                    ),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12 * scale,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _gender,
                                      hint: const Text('Chọn giới tính'),
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Nam',
                                          child: Text('Nam'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Nữ',
                                          child: Text('Nữ'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Khác',
                                          child: Text('Khác'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12 * scale),
                                _buildLabel('Ngày sinh', scale),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(
                                    12 * scale,
                                  ),
                                  child: Container(
                                    height: 46 * scale,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        12 * scale,
                                      ),
                                      border: Border.all(color: Colors.black26),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _dateOfBirth == null
                                                ? 'Chọn ngày sinh'
                                                : _formatDate(_dateOfBirth!),
                                            style: TextStyle(
                                              fontSize: 14 * scale,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12 * scale),
                                _buildLabel('Địa chỉ', scale),
                                _buildTextField(
                                  controller: _addressController,
                                  scale: scale,
                                  maxLines: 3,
                                ),
                                SizedBox(height: 22 * scale),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48 * scale,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF111111),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12 * scale,
                                        ),
                                      ),
                                    ),
                                    child: _saving
                                        ? SizedBox(
                                            width: 18 * scale,
                                            height: 18 * scale,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white,
                                                ),
                                          )
                                        : Text(
                                            'Lưu thay đổi',
                                            style: TextStyle(
                                              fontSize: 15 * scale,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13 * scale,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required double scale,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly ? const Color(0xFFF2F2F2) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 12 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
          borderSide: const BorderSide(color: Colors.black26),
        ),
      ),
    );
  }

  Future<void> _cacheProfile(
    AuthLocalDataSource local,
    Map<String, dynamic> profile, {
    Map<String, dynamic>? fallback,
  }) {
    final merged = {...?fallback, ...profile};
    return local.cacheUserProfile(
      id: _toInt(merged['userId']) ?? _toInt(merged['id']),
      accountId: _toInt(merged['accountId']) ?? _toInt(merged['id']),
      fullName: merged['fullName']?.toString(),
      email: merged['email']?.toString(),
      phone: merged['phone']?.toString(),
      gender: merged['gender']?.toString(),
      dateOfBirth: merged['dateOfBirth']?.toString(),
      address: merged['address']?.toString(),
      avatarUrl: merged['avatarUrl']?.toString(),
    );
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  DateTime? _tryParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double _uiScale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 700) {
      return (size.width / 390).clamp(0.75, 0.95);
    }
    return 1;
  }
}
