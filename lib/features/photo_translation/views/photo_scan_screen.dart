import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/photo_translation_controller.dart';
import 'language_picker_sheet.dart';
import '../../../core/services/permission_service.dart';

class PhotoScanScreen extends StatefulWidget {
  const PhotoScanScreen({super.key});

  @override
  State<PhotoScanScreen> createState() => _PhotoScanScreenState();
}

class _PhotoScanScreenState extends State<PhotoScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initFuture;
  late AnimationController _scanController;
  String? _cameraError;

  PhotoTranslationController get controller =>
      Get.find<PhotoTranslationController>();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameraError = null;
      final granted = await PermissionService.requestCamera();
      if (!granted) {
        if (mounted) {
          Get.snackbar('Permission', 'Camera permission is required');
          Get.back();
        }
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera available on this device.';
        });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initFuture = _cameraController!.initialize();
      setState(() {});
    } catch (_) {
      setState(() {
        _cameraError = 'Failed to initialize camera.';
      });
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null) return;
    if (controller.isProcessing.value || controller.isTranslating.value) return;

    if (_initFuture == null) return;
    _scanController.repeat();
    try {
      await _initFuture;
      final file = await _cameraController!.takePicture();
      await controller.processCapturedImage(File(file.path));
      if (mounted) {
        Get.back();
      }
    } finally {
      if (_scanController.isAnimating) {
        _scanController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final isProcessing = controller.isProcessing.value;
          final isTranslating = controller.isTranslating.value;
          final showSweep = isProcessing || isTranslating;
          final scanMessage =
              isTranslating ? 'Translating text...' : 'Reading text...';

          return Stack(
            children: [
              _buildCameraPreview(),
              _buildTopBar(),
              if (showSweep) _buildScanSweep(),
              if (showSweep) _buildScanOverlay(scanMessage),
              _buildShutterBar(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return _buildCameraError();
    }
    if (_cameraController == null || _initFuture == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to start camera.',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return CameraPreview(_cameraController!);
      },
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              _cameraError ?? 'Camera unavailable.',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cameraError = null;
                      _initFuture = null;
                    });
                    _initCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFB3),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
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

  Widget _buildTopBar() {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Obx(() {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detected: ${controller.detectedLanguageName.value}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildTargetSelector(context),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(BuildContext context) {
    return InkWell(
      onTap: () => showLanguagePickerSheet(
        context: context,
        languages: controller.supportedLanguages,
        selectedCode: controller.selectedTargetLanguage.value,
        onSelected: controller.selectTargetLanguage,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.selectedTargetLanguageName.value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildScanSweep() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _scanController,
        builder: (context, child) {
          return Align(
            alignment: Alignment(0, -1 + 2 * _scanController.value),
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF00FFB3).withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShutterBar() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _captureAndScan,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.camera, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay(String message) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF00FFB3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hold still for best results',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
