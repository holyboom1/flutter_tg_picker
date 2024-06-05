part of '../advanced_media_picker_impl.dart';

class AssetsService {
  final FilterOptionGroup _filterOptionGroup = FilterOptionGroup();

  Future<List<XFile>> onClose() async {
    final Completer<List<XFile>> completer = Completer<List<XFile>>();

    final List<XFile> assets = <XFile>[
      ...dataStore.capturedAssets.value,
    ];

    await Future.forEach(dataStore.selectedAssets.value, (AssetEntity element) async {
      final File? file = await element.file;
      if (file != null) {
        assets.add(XFile(file.path));
      }
    });
    dataStore.selectedAssets.value.clear();
    dataStore.availablePath.value.clear();
    dataStore.capturedAssets.value.clear();
    completer.complete(assets);
    return completer.future;
  }

  void onOnSelectAsset(AssetEntity asset) {
    if (dataStore.selectedAssets.value.contains(asset)) {
      dataStore.selectedAssets.value = <AssetEntity>[...dataStore.selectedAssets.value]
        ..remove(asset);
    } else {
      if (dataStore.limitToSelection != -1 &&
          dataStore.selectedAssets.value.length >= dataStore.limitToSelection) {
        return;
      }
      dataStore.selectedAssets.value = <AssetEntity>[...dataStore.selectedAssets.value, asset];
    }
  }

  Future<void> loadMoreAsset({
    required AssetPathEntity path,
  }) async {
    final int page = dataStore.pages[path.id]! + 1;
    final List<AssetEntity> entities = await path.getAssetListPaged(
      page: page,
      size: dataStore.sizePerPage,
    );
    dataStore.pathData[path.id]!.value = <AssetEntity>[
      ...dataStore.pathData[path.id]!.value,
      ...entities
    ];
    dataStore.pages[path.id] = page;
    dataStore.hasMoreToLoad[path.id] = entities.length < dataStore.totalEntitiesCount[path.id]!;
  }

  Future<void> getAssetsPath({
    required PickerAssetType allowedTypes,
  }) async {
    dataStore.availablePath.value = await PhotoManager.getAssetPathList(
      type: allowedTypes.toRequestType,
      filterOption: _filterOptionGroup,
    );

    if (dataStore.availablePath.value.isNotEmpty) {
      final List<AssetEntity> entities =
          await dataStore.availablePath.value.first.getAssetListPaged(
        page: 0,
        size: dataStore.sizePerPage,
      );
      dataStore.pathData[dataStore.availablePath.value.first.id] =
          ValueNotifier<List<AssetEntity>>(<AssetEntity>[]);

      dataStore.pathData[dataStore.availablePath.value.first.id]!.value = entities;
      dataStore.totalEntitiesCount[dataStore.availablePath.value.first.id] =
          await dataStore.availablePath.value.first.assetCountAsync;
      dataStore.pages[dataStore.availablePath.value.first.id] = 0;
      dataStore.hasMoreToLoad[dataStore.availablePath.value.first.id] =
          entities.length < dataStore.totalEntitiesCount[dataStore.availablePath.value.first.id]!;
      if (dataStore.availablePath.value.first == dataStore.availablePath.value.first) {
        dataStore.selectedPath.value = dataStore.availablePath.value.first;
      }
    }
  }

  Future<void> loadAssetPath(AssetPathEntity assetPath) async {
    final List<AssetEntity> entities = await assetPath.getAssetListPaged(
      page: 0,
      size: dataStore.sizePerPage,
    );
    dataStore.pathData[assetPath.id] = ValueNotifier<List<AssetEntity>>(<AssetEntity>[]);

    dataStore.pathData[assetPath.id]!.value = entities;
    dataStore.totalEntitiesCount[assetPath.id] = await assetPath.assetCountAsync;
    dataStore.pages[assetPath.id] = 0;
    dataStore.hasMoreToLoad[assetPath.id] =
        entities.length < dataStore.totalEntitiesCount[assetPath.id]!;
  }

  Future<bool> requestPermissions() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      return false;
    }
    return true;
  }
}
