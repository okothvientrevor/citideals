import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/auction_item.dart';
import '../../services/auctions_repository.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/pressable.dart';
import '../auth/auth_repository.dart';
import 'category_schemas.dart';
import 'dynamic_form.dart';

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = NumberFormat('#,##0').format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SubmitListingScreen extends ConsumerStatefulWidget {
  const SubmitListingScreen({super.key});

  @override
  ConsumerState<SubmitListingScreen> createState() =>
      _SubmitListingScreenState();
}

class _SubmitListingScreenState extends ConsumerState<SubmitListingScreen> {
  int _step = 0;
  String? _category;
  final _formStateKey = GlobalKey<DynamicFormState>();
  DynamicFormValues _categoryData = {};

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _startingBidCtrl = TextEditingController();
  final _minIncrementCtrl = TextEditingController(text: '10,000');
  DateTime _endTime = DateTime.now().add(const Duration(days: 7));

  final List<File> _images = [];
  bool _submitting = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _startingBidCtrl.dispose();
    _minIncrementCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _category == null) {
      _toast('Pick a category to continue');
      return;
    }
    if (_step == 1) {
      if (!(_formStateKey.currentState?.validate() ?? false)) return;
    }
    if (_step == 2 && _images.isEmpty) {
      _toast('Add at least one photo');
      return;
    }
    if (_step == 3) {
      _submit();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked) {
        if (_images.length < 8) _images.add(File(x.path));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _endTime = DateTime(
        date.year,
        date.month,
        date.day,
        _endTime.hour,
        _endTime.minute,
      );
    });
  }

  Future<void> _pickEndClock() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (time == null) return;
    setState(() {
      _endTime = DateTime(
        _endTime.year,
        _endTime.month,
        _endTime.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final session = ref.read(authStateProvider).value;
    if (session == null) {
      _toast('You need to sign in to submit.');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _toast('Title is required');
      setState(() => _step = 1);
      return;
    }
    final startingBid = double.tryParse(
      _startingBidCtrl.text.replaceAll(',', ''),
    );
    if (startingBid == null || startingBid <= 0) {
      _toast('Enter a starting bid');
      setState(() => _step = 1);
      return;
    }
    if (_endTime.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      _toast('End date/time must be at least 1 hour from now.');
      setState(() => _step = 1);
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });

    try {
      final cloud = ref.read(cloudinaryServiceProvider);
      final uploads = await cloud.uploadAll(
        _images,
        folder: 'citideals/${session.user.uid}',
        onProgress: (p) => setState(() => _uploadProgress = p),
      );

      final item = AuctionItem(
        id: '',
        sellerId: session.user.uid,
        sellerName: session.user.displayName ?? session.user.email,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category!,
        categoryData: _categoryData,
        imageUrls: uploads.map((u) => u.secureUrl).toList(),
        thumbnailUrl: uploads.first.thumbnail(),
        currentBid: startingBid,
        startingBid: startingBid,
        minBidIncrement:
            double.tryParse(_minIncrementCtrl.text.replaceAll(',', '')) ?? 100,
        endTime: _endTime,
        status: AuctionStatus.pending,
        schemaVersion: schemaVersion,
      );

      await ref.read(auctionsRepositoryProvider).createSubmission(item);

      if (mounted) {
        HapticFeedback.mediumImpact();
        showAppBanner(
          context,
          'Submitted! Admins will review shortly.',
          type: AppBannerType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    showAppBanner(context, msg, type: AppBannerType.error);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Category', 'Details', 'Photos', 'Review'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
        title: const Text('List an item'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: EdgeInsets.only(
                        right: i == steps.length - 1 ? 0 : 6,
                      ),
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: active ? AppTheme.primaryGradient : null,
                        color: active
                            ? null
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_step + 1} of ${steps.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    steps[_step],
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
            _BottomBar(
              primaryLabel: _step == 3 ? 'Submit for review' : 'Continue',
              onPrimary: _submitting ? null : _next,
              onSecondary: _back,
              secondaryLabel: _step == 0 ? 'Cancel' : 'Back',
              loading: _submitting,
              progress: _submitting ? _uploadProgress : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _categoryStep(),
      1 => _detailsStep(),
      2 => _photosStep(),
      _ => _reviewStep(),
    };
  }

  void _showMoreCategories() {
    final theme = Theme.of(context);
    final entries = moreCategories.entries.toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'More categories',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (sheetCtx, i) {
                    final cat = entries[i].value;
                    return Pressable(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _category = cat.name;
                          _categoryData = {};
                          _step = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                cat.icon,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            Text(
                              cat.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryStep() {
    final theme = Theme.of(context);
    final entries = categorySchemas.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are you listing?', style: theme.textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(
          'We use the category to ask the right questions.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: entries.length + 1,
          itemBuilder: (context, i) {
            // "Other" tile — last in the grid
            if (i == entries.length) {
              return Pressable(
                onTap: _showMoreCategories,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Other',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            final cat = entries[i].value;
            final selected = _category == cat.name;
            return Pressable(
              onTap: () => setState(() {
                _category = cat.name;
                _categoryData = {};
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: selected ? AppTheme.primaryGradient : null,
                  color: selected ? null : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(0.18)
                            : AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        cat.icon,
                        color: selected ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    Text(
                      cat.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _detailsStep() {
    final theme = Theme.of(context);
    final schema = allCategorySchemas[_category]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your ${schema.name.toLowerCase()}',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'These details show up on the listing page.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _titleCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Title',
            prefixIcon: Icon(Icons.title_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descCtrl,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Description (history, condition notes, story)',
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starting Bid (UGX)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _startingBidCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsFormatter()],
                    decoration: const InputDecoration(prefixText: 'UGX '),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minimum Increment (UGX)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _minIncrementCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsFormatter()],
                    decoration: const InputDecoration(prefixText: 'UGX '),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Auction end date & time', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Pressable(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End date', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${_endTime.year}-${_endTime.month.toString().padLeft(2, '0')}-${_endTime.day.toString().padLeft(2, '0')}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Pressable(
                onTap: _pickEndClock,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End time', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('${schema.name} details', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        DynamicForm(
          key: _formStateKey,
          fields: schema.fields,
          initial: _categoryData,
          onChanged: (v) => _categoryData = v,
        ),
      ],
    );
  }

  void _previewImage(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(child: InteractiveViewer(child: Image.file(file))),
        ),
      ),
    );
  }

  void _onTapImage(int index) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: const Text('Preview full screen'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _previewImage(_images[index]);
                  },
                ),
                if (index != 0)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AppTheme.accent,
                      ),
                    ),
                    title: const Text('Set as cover photo'),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        final img = _images.removeAt(index);
                        _images.insert(0, img);
                      });
                    },
                  ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.coral,
                    ),
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: AppTheme.coral),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _images.removeAt(index));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photosStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add photos', style: theme.textTheme.displaySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Up to 8 images. First photo is the cover.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (_images.isNotEmpty)
              Text(
                '${_images.length}/8',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _images.length < 8 ? _images.length + 1 : _images.length,
          itemBuilder: (context, i) {
            if (i == _images.length) {
              // Add-photo tile
              return Pressable(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: AppTheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add photos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isCover = i == 0;
            return Pressable(
              onTap: () => _onTapImage(i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_images[i], fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                          stops: const [0.0, 0.25, 0.65, 1.0],
                        ),
                      ),
                    ),
                    if (isCover)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'COVER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppTheme.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap a photo to preview, set as cover, or remove it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _reviewStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & submit', style: theme.textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(
          'Admins will approve or reject. You\'ll be notified.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (_images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.file(_images.first, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 14),
        Text(
          _titleCtrl.text,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _category ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Ends ${_formatDate(_endTime)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              _reviewRow(
                'Starting bid',
                'UGX ${NumberFormat('#,##0').format(int.tryParse(_startingBidCtrl.text.replaceAll(',', '')) ?? 0)}',
              ),
              _reviewRow(
                'Min increment',
                'UGX ${NumberFormat('#,##0').format(int.tryParse(_minIncrementCtrl.text.replaceAll(',', '')) ?? 0)}',
              ),
              _reviewRow('Photos', '${_images.length}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _BottomBar extends StatelessWidget {
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onSecondary;
  final bool loading;
  final double? progress;

  const _BottomBar({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.loading,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading… ${(progress! * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: onSecondary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          secondaryLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: onPrimary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Center(
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                primaryLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
