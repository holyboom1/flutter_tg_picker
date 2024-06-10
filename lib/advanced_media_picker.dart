library advanced_media_picker;

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'advanced_media_picker_impl.dart';
import 'models/asset_model.dart';
import 'models/camera_style.dart';
import 'models/picker_controller.dart';
import 'models/picker_style.dart';

export 'package:cross_file/cross_file.dart' show XFile;

export 'advanced_media_picker_impl.dart' show PickerAssetType;
export 'models/camera_style.dart';
export 'models/close_alert_style.dart';
export 'models/picker_controller.dart';
export 'models/picker_style.dart';

/// A Flutter plugin for selecting images and videos from the Android and iOS image library, and taking new pictures with the camera.
class AdvancedMediaPicker {
  /// Opens the picker to select images and videos from the Android and iOS image library.
  static Future<List<XFile>> openPicker({
    required BuildContext context,
    bool isNeedToShowCamera = true,
    bool isNeedVideoCamera = true,
    int maxVideoDuration = -1,
    List<String> fileSelectorAllowedTypes = const <String>['pdf', 'doc'],

    /// The maximum number of files that can be selected in the picker.
    /// If the value is -1, it means that there is no limit to the number of files that can be selected.
    int selectionLimit = 3,
    PickerAssetType? allowedTypes,
    PickerController? controller,
    PickerStyle? style,
    CameraStyle? cameraStyle,
  }) async {
    dataStore = DataStore(
      style: style ?? PickerStyle(),
      cameraStyle: cameraStyle ?? CameraStyle(),
      pickerController: controller ?? PickerController(),
    );
    assetsService = AssetsService();

    dataStore.limitToSelection = selectionLimit;
    dataStore.maxVideoDuration = maxVideoDuration;
    dataStore.isNeedToShowCamera = isNeedToShowCamera;
    dataStore.isNeedToTakeVideo = isNeedVideoCamera;
    dataStore.allowedTypes.addAll(fileSelectorAllowedTypes);

    if (!await assetsService.requestPermissions()) {
      throw Exception('Permission denied');
    }
    await assetsService.getAssetsPath(
      allowedTypes: allowedTypes ?? PickerAssetType.all,
    );

    unawaited(
      Navigator.push(
        context,
        PageRouteBuilder<void>(
          barrierColor: Colors.black26,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ),
              ),
              child: const PickerBottomSheet(),
            );
          },
          opaque: false,
          fullscreenDialog: true,
          barrierDismissible: true,
          pageBuilder: (_, __, ___) {
            return const PickerBottomSheet();
          },
        ),
      ).then(
        (void _) {
          Future<void>.delayed(const Duration(milliseconds: 300), () {
            dataStore.cameraController?.dispose();
          });
        },
      ),
    );

    return dataStore.mainCompleter.future;
  }

  /// Opens file picker to select files from the device, use this in case when you use custom bottom widget
  static Future<List<AssetModel>> selectFilesFromDevice() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: dataStore.allowedTypes,
    );

    if (result != null) {
      final List<AssetModel> assets = <AssetModel>[];
      for (final XFile file in result.xFiles) {
        final AssetModel asset = AssetModel.fromXFile(XFile(file.path));
        assets.add(asset);
      }
      dataStore.selectedAssets.value = assets;
      await assetsService.onClose();
      return assets;
    }
    return <AssetModel>[];
  }
}
