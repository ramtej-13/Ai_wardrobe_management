import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/theme.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';

class UploadClothingScreen extends ConsumerStatefulWidget {
  const UploadClothingScreen({super.key});

  @override
  ConsumerState<UploadClothingScreen> createState() => _UploadClothingScreenState();
}

class _UploadClothingScreenState extends ConsumerState<UploadClothingScreen> with SingleTickerProviderStateMixin {
  XFile? _image;
  final _picker = ImagePicker();
  bool _isScanning = false;

  // Rich AI loading state
  int _loadingStep = 0;
  Timer? _loadingTimer;
  final List<String> _scanMessages = [
    'Scanning fabric textures...',
    'Extracting color palette...',
    'Identifying item category...',
    'Analyzing fit and style attributes...',
    'Saving details to database...',
  ];

  // Animation for scanning bar
  late AnimationController _animController;
  late Animation<double> _scannerPosition;

  // Form controllers
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fitController = TextEditingController();

  AIClothingAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scannerPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _animController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    _fitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _isScanning = true;
        _loadingStep = 0;
      });
      
      _loadingTimer?.cancel();
      _loadingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (mounted && _isScanning) {
          setState(() {
            _loadingStep = (_loadingStep + 1) % _scanMessages.length;
          });
        } else {
          timer.cancel();
        }
      });
      
      _animController.repeat(reverse: true);
      _runClothingAnalysis();
    }
  }

  Future<void> _runClothingAnalysis() async {
    if (_image == null) return;

    final analysisResult = await ref.read(wardrobeProvider.notifier).scanClothing(_image!);
    
    _loadingTimer?.cancel();
    _animController.stop();
    setState(() => _isScanning = false);

    if (analysisResult != null) {
      setState(() {
        _analysis = analysisResult;
        
        // Populate inputs
        final cat = analysisResult.category.value;
        final col = analysisResult.color.value;
        final fitVal = analysisResult.fit.value;
        
        _nameController.text = '$col $cat';
        _categoryController.text = cat;
        _colorController.text = col;
        _descriptionController.text = analysisResult.description.value;
        _fitController.text = fitVal;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze image. Please try manually.')),
        );
      }
    }
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for the item')),
      );
      return;
    }

    final newItem = WardrobeItem(
      id: '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      color: _colorController.text.trim(),
      description: _descriptionController.text.trim(),
      dateAdded: DateTime.now().toIsoformat(),
      fit: _fitController.text.trim().isEmpty ? 'Regular' : _fitController.text.trim(),
      imagePath: _analysis?.imagePath,
    );

    final success = await ref.read(wardrobeProvider.notifier).addItem(newItem);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clothing item saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtelierTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Clothing Scan',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _image == null
              ? _buildPickerSelector()
              : _isScanning
                  ? _buildScannerView()
                  : _buildResultsForm(),
        ),
      ),
    );
  }

  Widget _buildPickerSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: AtelierTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AtelierTheme.border, width: 1.5),
                ),
                child: const Icon(Icons.checkroom, color: AtelierTheme.accent, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                'Add to Closet',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Let the AI Wardrobe Vision Engine identify style categories, color shades, fits, and description patterns.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AtelierTheme.secondaryText, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildPickerButton(
          icon: Icons.camera_alt_outlined,
          label: 'TAKE A PHOTO',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 16),
        _buildPickerButton(
          icon: Icons.photo_library_outlined,
          label: 'CHOOSE FROM GALLERY',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AtelierTheme.border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AtelierTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AtelierTheme.border, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(_image!.path, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), fit: BoxFit.cover),
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Positioned(
                        top: _scannerPosition.value * 290,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AtelierTheme.accent.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 4,
                              )
                            ],
                            color: AtelierTheme.accent,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _scanMessages[_loadingStep],
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Extracting fits, fabric weaves, and style shades.',
            style: GoogleFonts.inter(fontSize: 13, color: AtelierTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AtelierTheme.border, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: kIsWeb
                    ? Image.network(_image!.path, fit: BoxFit.cover)
                    : Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'VERIFY DETAILS',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Review AI detected properties and adjust before saving to your closet.',
            style: GoogleFonts.inter(fontSize: 13, color: AtelierTheme.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildEditField(label: 'NAME', controller: _nameController),
          _buildEditField(
            label: 'CATEGORY',
            controller: _categoryController,
            confidence: _analysis?.category.confidence,
          ),
          _buildEditField(
            label: 'COLOR',
            controller: _colorController,
            confidence: _analysis?.color.confidence,
          ),
          _buildEditField(
            label: 'FIT',
            controller: _fitController,
            confidence: _analysis?.fit.confidence,
          ),
          _buildEditField(
            label: 'DESCRIPTION',
            controller: _descriptionController,
            maxLines: 3,
            confidence: _analysis?.description.confidence,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AtelierTheme.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(
                'SAVE TO CLOSET',
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    double? confidence,
  }) {
    final showConfidence = confidence != null;
    final isLowConfidence = showConfidence && confidence < 0.85;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              if (showConfidence)
                Text(
                  isLowConfidence
                      ? '⚠️ VERIFY (Conf: ${(confidence * 100).round()}%)'
                      : '✓ CONFIRMED (Conf: ${(confidence * 100).round()}%)',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLowConfidence ? Colors.amber : AtelierTheme.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AtelierTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isLowConfidence ? Colors.amber : AtelierTheme.accent,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension DateTimeExtensions on DateTime {
  String toIsoformat() {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
