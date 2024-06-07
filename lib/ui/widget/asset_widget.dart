part of '../../advanced_media_picker_impl.dart';

class AssetWidget extends StatelessWidget {
  final AssetEntity asset;

  const AssetWidget({
    super.key,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => assetsService.onOnSelectAsset(asset),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: dataStore.style.itemsBorderRadius,
          color: dataStore.selectedAssets.value.containsAsset(asset)
              ? Colors.blue.withOpacity(0.5)
              : Colors.transparent,
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AssetEntityImage(
                asset,
                fit: BoxFit.cover,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize(150, 150),
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  return loadingProgress == null
                      ? child
                      : Shimmer.fromColors(
                          baseColor: dataStore.style.shimmerBaseColor,
                          highlightColor: dataStore.style.shimmerHighlightColor,
                          child: child,
                        );
                },
              ),
            ),
            ValueListenableBuilder<List<AssetModel>>(
              valueListenable: dataStore.selectedAssets,
              builder: (BuildContext context, List<AssetModel> value,
                  Widget? child) {
                return Align(
                  alignment: dataStore.style.selectIconAlignment,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dataStore.style.selectIconBackgroundColor,
                        border: dataStore.style.selectIconBorder,
                        shape: BoxShape.circle,
                      ),
                      child: dataStore.selectedAssets.value.containsAsset(asset)
                          ? dataStore.style.selectIcon
                          : const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
