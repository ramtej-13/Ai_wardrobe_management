import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/theme.dart';
import '../models/user.dart';
import '../providers/profile_provider.dart';
import 'navigation_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  
  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '65');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).profile.value;
      if (profile != null && profile.name.isNotEmpty) {
        _nameController.text = profile.name;
        _ageController.text = profile.age > 0 ? profile.age.toString() : '';
        _locationController.text = profile.location;
        _occupationController.text = profile.occupation;
        _heightController.text = profile.height > 0 ? profile.height.toString() : '170';
        _weightController.text = profile.weight > 0 ? profile.weight.toString() : '65';
        setState(() {
          _selectedGender = profile.gender.isEmpty ? 'Male' : profile.gender;
          _selectedStyle = profile.preferredStyle.isEmpty ? 'Casual' : profile.preferredStyle;
          _selectedBudget = profile.budget.isEmpty ? 'Moderate' : profile.budget;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  String _selectedGender = 'Male';
  String _selectedStyle = 'Casual';
  String _selectedBudget = 'Moderate';

  // Photo slots
  XFile? _frontPhoto;
  XFile? _sidePhoto;
  XFile? _facePhoto;
  
  final _picker = ImagePicker();

  Future<void> _pickImage(String slot) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (slot == 'front') {
          _frontPhoto = pickedFile;
        } else if (slot == 'side') {
          _sidePhoto = pickedFile;
        } else if (slot == 'face') {
          _facePhoto = pickedFile;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    final notifier = ref.read(profileProvider.notifier);
    
    // Construct base profile
    final baseProfile = UserProfile(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 25,
      gender: _selectedGender,
      location: _locationController.text.trim().isEmpty ? 'Not Specified' : _locationController.text.trim(),
      budget: _selectedBudget,
      preferredStyle: _selectedStyle,
      occupation: _occupationController.text.trim().isEmpty ? 'Not Specified' : _occupationController.text.trim(),
      height: double.tryParse(_heightController.text.trim()) ?? 170.0,
      weight: double.tryParse(_weightController.text.trim()) ?? 65.0,
      bodyType: AICoordinate(value: 'N/A', confidence: 0.0),
      bodyBuild: AICoordinate(value: 'N/A', confidence: 0.0),
      skinTone: AICoordinate(value: 'N/A', confidence: 0.0),
      undertone: AICoordinate(value: 'N/A', confidence: 0.0),
      hairColor: AICoordinate(value: 'N/A', confidence: 0.0),
      faceShape: AICoordinate(value: 'N/A', confidence: 0.0),
      facialHair: AICoordinate(value: 'N/A', confidence: 0.0),
      estimatedHeight: AICoordinate(value: 'N/A', confidence: 0.0),
    );

    // If photos are provided, perform biometric analysis
    if (_frontPhoto != null && _sidePhoto != null && _facePhoto != null) {
      final success = await notifier.scanBiometrics(
        baseProfile: baseProfile,
        front: _frontPhoto!,
        side: _sidePhoto!,
        face: _facePhoto!,
      );
      
      if (!success) {
        // If scan failed, still save manual fields
        await notifier.saveProfile(baseProfile);
      }
    } else {
      await notifier.saveProfile(baseProfile);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: SafeArea(
        child: profileState.isScanning
            ? _buildScanningOverlay()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _currentStep == 0 ? _buildManualForm() : _buildPhotoUploadForm(),
                      ),
                    ),
                    _buildFooterButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style Profile',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStep == 0
              ? 'Tell us about your style and basic attributes.'
              : 'Add photos to analyze biometric properties via Vision AI.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AtelierTheme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(label: 'NAME', controller: _nameController, hint: 'e.g. Sarah Connor'),
        _buildTextField(label: 'AGE', controller: _ageController, hint: 'e.g. 28', keyboardType: TextInputType.number),
        _buildTextField(label: 'LOCATION', controller: _locationController, hint: 'e.g. Paris, FR'),
        _buildTextField(label: 'OCCUPATION', controller: _occupationController, hint: 'e.g. Product Designer'),
        _buildTextField(label: 'HEIGHT (CM)', controller: _heightController, hint: 'e.g. 170', keyboardType: TextInputType.number),
        _buildTextField(label: 'WEIGHT (KG)', controller: _weightController, hint: 'e.g. 65', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildSelectionTitle('PREFERRED STYLE'),
        _buildStyleChips(),
        const SizedBox(height: 16),
        _buildSelectionTitle('BUDGET TIER'),
        _buildBudgetChips(),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15),
              filled: true,
              fillColor: AtelierTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AtelierTheme.accent, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }

  Widget _buildStyleChips() {
    final styles = ['Casual', 'Streetwear', 'Formal', 'Vintage', 'Athletic'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: styles.map((style) {
        final isSelected = _selectedStyle == style;
        return GestureDetector(
          onTap: () => setState(() => _selectedStyle = style),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AtelierTheme.accent.withOpacity(0.1) : AtelierTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AtelierTheme.accent : AtelierTheme.border,
                width: 1,
              ),
            ),
            child: Text(
              style,
              style: GoogleFonts.inter(
                color: isSelected ? AtelierTheme.accent : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetChips() {
    final budgets = ['Budget', 'Moderate', 'Luxury'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: budgets.map((budget) {
        final isSelected = _selectedBudget == budget;
        return GestureDetector(
          onTap: () => setState(() => _selectedBudget = budget),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AtelierTheme.accent.withOpacity(0.1) : AtelierTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AtelierTheme.accent : AtelierTheme.border,
                width: 1,
              ),
            ),
            child: Text(
              budget,
              style: GoogleFonts.inter(
                color: isSelected ? AtelierTheme.accent : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoUploadForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoSlot(title: 'FRONT BODY PROFILE', file: _frontPhoto, slot: 'front'),
        const SizedBox(height: 20),
        _buildPhotoSlot(title: 'SIDE BODY PROFILE', file: _sidePhoto, slot: 'side'),
        const SizedBox(height: 20),
        _buildPhotoSlot(title: 'FACE BIOMETRIC', file: _facePhoto, slot: 'face'),
      ],
    );
  }

  Widget _buildPhotoSlot({required String title, XFile? file, required String slot}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(slot),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AtelierTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AtelierTheme.border, width: 1),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: kIsWeb
                        ? Image.network(file.path, fit: BoxFit.cover)
                        : Image.file(File(file.path), fit: BoxFit.cover),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AtelierTheme.secondaryText, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Image',
                          style: GoogleFonts.inter(color: AtelierTheme.secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      color: AtelierTheme.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                Center(
                  child: Icon(Icons.security_update_good_outlined, color: AtelierTheme.accent, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Biometrics...',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'AI Wardrobe Vision Engine is scanning body profiles.',
            style: GoogleFonts.inter(fontSize: 13, color: AtelierTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: AtelierTheme.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Text(
          _currentStep == 0 ? 'CONTINUE' : 'FINALIZE PROFILE',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
