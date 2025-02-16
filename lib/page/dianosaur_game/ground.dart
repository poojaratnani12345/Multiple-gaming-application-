import 'package:flutter/widgets.dart';
import 'constants.dart';
import 'game_object.dart';
import 'ImageModel.dart';

ImageModel groundImageModel = ImageModel()
  ..imagePath = "assets/images/dianoser_game/land.png"
  ..imageWidth = 2399
  ..imageHeight = 100;

class Ground extends GameObject {
  late final Offset worldLocation;

  Ground({required this.worldLocation});

  @override
  Rect getRect(Size screenSize, double runDistance) {
    return Rect.fromLTWH(
      (worldLocation.dx - runDistance) * worlToPixelRatio,
      screenSize.height - groundImageModel.imageHeight * 7,  // Adjust this for height scaling
      groundImageModel.imageWidth.toDouble() * 5,  // Adjust width scaling
      groundImageModel.imageHeight.toDouble() * 7,  // Adjust height scaling
    );
  }

  @override
  Widget render() {
    return Positioned(
      left: worldLocation.dx,  // Adjust position if necessary
      bottom: 5,
      child: Image.asset(
        groundImageModel.imagePath,
        width: groundImageModel.imageWidth.toDouble() * 5,  // Apply the same scaling as in getRect
        height: groundImageModel.imageHeight.toDouble() * 7,  // Apply the same scaling as in getRect
        fit: BoxFit.fill,
      ),
    );
  }
}
