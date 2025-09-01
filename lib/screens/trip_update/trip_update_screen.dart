import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../models/dispatch.dart';

class TripUpdateScreen extends StatefulWidget {
  final String dispatchId;
  final String driverId;
  final String updateType; // 'start', 'update', or 'complete'

  const TripUpdateScreen({
    super.key,
    required this.dispatchId,
    required this.driverId,
    required this.updateType,
  });

  @override
  State<TripUpdateScreen> createState() => _TripUpdateScreenState();
}

class _TripUpdateScreenState extends State<TripUpdateScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  final _messageController = TextEditingController();

  List<DispatchImage> _uploadedImages = [];
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUploadedImages();
  }

  // Notification service methods
  Future<void> _sendNotifications(String updateType, String description) async {
    try {
      final now = DateTime.now();
      final dispatchDoc = await _firestore
          .collection('dispatches')
          .doc(widget.dispatchId)
          .get();

      if (!dispatchDoc.exists) return;

      final dispatchData = dispatchDoc.data()!;
      final driverAssignments =
          dispatchData['driverAssignments'] as Map<String, dynamic>? ?? {};

      // Get driver info
      final driverDoc = await _firestore
          .collection('drivers')
          .doc(widget.driverId)
          .get();
      String driverName = 'Driver';
      if (driverDoc.exists) {
        final driverData = driverDoc.data();
        driverName = driverData?['name'] ?? 'Driver';
      }

      String message;
      String title;
      String priority;

      if (updateType == 'start') {
        message =
            'Trip ${widget.dispatchId} has been started by driver $driverName';
        title = 'Trip Started';
        priority = 'normal';
      } else if (updateType == 'complete') {
        message =
            'Trip ${widget.dispatchId} has been completed by driver $driverName';
        title = 'Trip Completed';
        priority = 'normal';
      } else {
        // This is an emergency/update during trip
        message =
            'Emergency update from driver $driverName on trip ${widget.dispatchId}: $description';
        title = 'Trip Emergency Update';
        priority = 'high';
      }

      // For start/complete: send to global, all drivers, and customer
      if (updateType == 'start' || updateType == 'complete') {
        // 1. Global notifications
        await _firestore.collection('notifications').add({
          'title': title,
          'audience': 'admin',
          'createdAt': now,
          'isRead': false,
          'message': message,
          'priority': priority,
          'recipientId': 'admin',
          'scheduledFor': now.toIso8601String().substring(0, 16),
        });

        // 2. Driver notifications (to all drivers in this dispatch)
        for (String driverId in driverAssignments.keys) {
          await _firestore
              .collection('drivers')
              .doc(driverId)
              .collection('notifications')
              .add({
                'isRead': false,
                'message': message,
                'priority': priority,
                'read': false,
                'readAt': null,
                'senderId': widget.driverId,
                'timestamp': now,
                'title': title,
                'type': 'trip_update',
              });
        }

        // 3. Customer notification
        final customerId = dispatchData['customerId'];
        if (customerId != null) {
          await _firestore
              .collection('customers')
              .doc(customerId)
              .collection('notifications')
              .add({
                'dispatchId': widget.dispatchId,
                'isRead': false,
                'message': message,
                'priority': priority,
                'read': false,
                'readAt': null,
                'senderId': widget.driverId,
                'timestamp': now,
                'title': title,
                'type': 'trip_update',
              });
        }
      } else {
        // For emergency updates during trip: only global notifications
        await _firestore.collection('notifications').add({
          'title': title,
          'audience': 'admin',
          'createdAt': now,
          'isRead': false,
          'message': message,
          'priority': priority,
          'recipientId': 'admin',
          'scheduledFor': now.toIso8601String().substring(0, 16),
        });
      }
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  Future<void> _loadUploadedImages() async {
    try {
      print(
        'Loading images for dispatchId: ${widget.dispatchId}, driverId: ${widget.driverId}',
      );

      final querySnapshot = await _firestore
          .collection('dispatch_image')
          .where('dispatchId', isEqualTo: widget.dispatchId)
          .where('driverId', isEqualTo: widget.driverId)
          .orderBy('uploadedAt', descending: true)
          .get();

      print(
        'Found ${querySnapshot.docs.length} images in dispatch_image collection',
      );

      setState(() {
        _uploadedImages = querySnapshot.docs.map((doc) {
          print('Image doc data: ${doc.data()}');
          return DispatchImage.fromFirestore(doc.data(), doc.id);
        }).toList();
      });

      print('Loaded ${_uploadedImages.length} images successfully');
    } catch (e) {
      print('Error loading images: $e');

      // If the error is about missing index, try a simpler query
      if (e.toString().contains('index') || e.toString().contains('Index')) {
        print('Trying alternative query without orderBy...');
        try {
          final querySnapshot = await _firestore
              .collection('dispatch_image')
              .where('dispatchId', isEqualTo: widget.dispatchId)
              .where('driverId', isEqualTo: widget.driverId)
              .get();

          print('Alternative query found ${querySnapshot.docs.length} images');

          setState(() {
            _uploadedImages = querySnapshot.docs
                .map((doc) => DispatchImage.fromFirestore(doc.data(), doc.id))
                .toList();

            // Sort manually by uploadedAt
            _uploadedImages.sort(
              (a, b) => b.uploadedAt.compareTo(a.uploadedAt),
            );
          });
        } catch (e2) {
          print('Alternative query also failed: $e2');
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error picking image')));
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    // Always require description/reason for image upload
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description/reason for this image'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.driverId}_$timestamp.jpg';
      final storagePath =
          'dispatches/${widget.dispatchId}/${widget.driverId}/$fileName';

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = await storageRef.putFile(_selectedImage!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save to Firestore
      final imageData = DispatchImage(
        id: '', // Will be set by Firestore
        dispatchId: widget.dispatchId,
        driverId: widget.driverId,
        imageUrl: downloadUrl,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        uploadedAt: DateTime.now(),
        imageName: fileName,
      );

      print(
        'Saving image data to dispatch_image collection: ${imageData.toMap()}',
      );
      await _firestore.collection('dispatch_image').add(imageData.toMap());
      print('Image saved successfully to dispatch_image collection');

      // Update driver status in dispatch if this is start or complete
      if (widget.updateType == 'start' || widget.updateType == 'complete') {
        final dispatchRef = _firestore
            .collection('dispatches')
            .doc(widget.dispatchId);
        final now = Timestamp.now();

        if (widget.updateType == 'start') {
          await dispatchRef.update({
            'driverAssignments.${widget.driverId}.status': 'in-progress',
            'driverAssignments.${widget.driverId}.startedAt': now,
          });
        } else if (widget.updateType == 'complete') {
          await dispatchRef.update({
            'driverAssignments.${widget.driverId}.status': 'completed',
            'driverAssignments.${widget.driverId}.completedAt': now,
          });
        }
      }

      // Send notifications
      await _sendNotifications(
        widget.updateType,
        _messageController.text.trim(),
      );

      // Clear form
      setState(() {
        _selectedImage = null;
        _messageController.clear();
      });

      // Reload images
      await _loadUploadedImages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );

      // If this is start or complete, go back
      if (widget.updateType == 'start' || widget.updateType == 'complete') {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error uploading image')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteImage(DispatchImage image) async {
    final shouldDelete = await _showConfirmDialog(
      'Are you sure you want to delete this image?',
    );

    if (!shouldDelete) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Delete from Firebase Storage
      final storageRef = _storage.refFromURL(image.imageUrl);
      await storageRef.delete();

      // Delete from Firestore
      await _firestore.collection('dispatch_image').doc(image.id).delete();

      // Reload images
      await _loadUploadedImages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      print('Error deleting image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error deleting image')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageDialog(DispatchImage image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Background tap to close
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black87,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Image content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    // Full image
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            image.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                padding: const EdgeInsets.all(20),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Image info
                    if (image.message != null)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              image.message!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDateTime(image.uploadedAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _screenTitle {
    switch (widget.updateType) {
      case 'start':
        return 'Start Trip - Upload Image';
      case 'complete':
        return 'Complete Trip - Upload Image';
      default:
        return 'Trip Updates';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Prevent overflow when keyboard appears
      appBar: AppBar(
        title: Text(_screenTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Make the entire body scrollable
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Image Upload Section
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.updateType == 'start'
                                ? 'Take a photo to start the trip'
                                : widget.updateType == 'complete'
                                ? 'Take a photo to complete the trip'
                                : 'Add a trip update',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Image Preview
                          if (_selectedImage != null)
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                color: Colors.grey.shade50,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to take a photo',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Take Photo Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              label: Text(
                                _selectedImage != null
                                    ? 'Retake Photo'
                                    : 'Take Photo',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Description Input (Required)
                          TextField(
                            controller: _messageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description/Reason *',
                              hintText:
                                  'Please describe the reason for this image (required)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              helperText:
                                  'Required: Explain why you are taking this photo',
                              helperStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Upload Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _uploadImage,
                              icon: const Icon(
                                Icons.upload,
                                color: Colors.white,
                              ),
                              label: Text(
                                widget.updateType == 'start'
                                    ? 'Start Trip'
                                    : widget.updateType == 'complete'
                                    ? 'Complete Trip'
                                    : 'Upload Update',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.updateType == 'start'
                                    ? Colors.green
                                    : AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Previous Images Section
                  Container(
                    height: 300, // Fixed height instead of Expanded
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Previous Updates',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _loadUploadedImages,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'Refresh images',
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Expanded(
                              child: _uploadedImages.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.photo_library_outlined,
                                            size: 48,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No updates yet',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Upload images to track progress',
                                            style: TextStyle(
                                              color: AppColors.textTertiary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _uploadedImages.length,
                                      itemBuilder: (context, index) {
                                        final image = _uploadedImages[index];
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.2,
                                                ),
                                                spreadRadius: 1,
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Image with tap to expand
                                              GestureDetector(
                                                onTap: () =>
                                                    _showImageDialog(image),
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                            topRight:
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                      child: Image.network(
                                                        image.imageUrl,
                                                        width: double.infinity,
                                                        height: 120,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder:
                                                            (
                                                              context,
                                                              child,
                                                              progress,
                                                            ) {
                                                              if (progress ==
                                                                  null)
                                                                return child;
                                                              return Container(
                                                                height: 120,
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                                child: const Center(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ),
                                                              );
                                                            },
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Container(
                                                                height: 120,
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                                child: const Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    color: Colors
                                                                        .grey,
                                                                    size: 40,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                    ),
                                                    // Tap to expand overlay
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black54,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.zoom_in,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Info and Actions
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (image.message != null)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          image.message!,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .textPrimary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              _formatDateTime(
                                                                image
                                                                    .uploadedAt,
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .textSecondary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors.red
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: IconButton(
                                                            onPressed: () =>
                                                                _deleteImage(
                                                                  image,
                                                                ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color: Colors.red,
                                                            ),
                                                            iconSize: 18,
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            constraints:
                                                                const BoxConstraints(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
