import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  Directory('assets/icons').createSync(recursive: true);
  Directory('assets/images').createSync(recursive: true);

  generateAppIcon();
  generateVillaCourtyard();
  generatePenthouseLoft();
  generateCommercialHub();
  generateSmartTownhouse();
  generateBlueprintFloorplan();
  generateAdvisorAvatar('assets/images/advisor_sarah.png', img.ColorRgb8(16, 185, 129), img.ColorRgb8(5, 150, 105), 'SC');
  generateAdvisorAvatar('assets/images/advisor_omar.png', img.ColorRgb8(59, 130, 246), img.ColorRgb8(29, 78, 216), 'OH');
  generateAdvisorAvatar('assets/images/advisor_elena.png', img.ColorRgb8(245, 158, 11), img.ColorRgb8(180, 83, 9), 'ER');

  print('All assets generated successfully.');
}

void generateAppIcon() {
  const size = 512;
  final image = img.Image(width: size, height: size);
  
  // Background: Obsidian slate gradient
  for (int y = 0; y < size; y++) {
    final t = y / size;
    final r = (15 * (1 - t) + 10 * t).round();
    final g = (23 * (1 - t) + 15 * t).round();
    final b = (42 * (1 - t) + 30 * t).round();
    for (int x = 0; x < size; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Draw architectural grid lines
  final gridColor = img.ColorRgb8(30, 41, 59);
  for (int x = 64; x < size; x += 64) {
    img.drawLine(image, x1: x, y1: 40, x2: x, y2: size - 40, color: gridColor);
  }
  for (int y = 64; y < size; y += 64) {
    img.drawLine(image, x1: 40, y1: y, x2: size - 40, y2: y, color: gridColor);
  }

  // Golden compass azimuth arc
  final goldColor = img.ColorRgb8(245, 158, 11);
  final emeraldColor = img.ColorRgb8(16, 185, 129);
  final whiteSlate = img.ColorRgb8(241, 245, 249);
  final darkEmerald = img.ColorRgb8(4, 120, 87);

  // Compass outer circle
  img.drawCircle(image, x: 256, y: 256, radius: 180, color: goldColor);
  img.drawCircle(image, x: 256, y: 256, radius: 178, color: goldColor);

  // Cantilevered villa roofline and structural geometry
  // Roofline angle: (100, 260) -> (256, 140) -> (412, 260)
  img.drawLine(image, x1: 96, y1: 260, x2: 256, y2: 140, color: emeraldColor);
  img.drawLine(image, x1: 96, y1: 261, x2: 256, y2: 141, color: emeraldColor);
  img.drawLine(image, x1: 96, y1: 262, x2: 256, y2: 142, color: emeraldColor);

  img.drawLine(image, x1: 256, y1: 140, x2: 416, y2: 260, color: emeraldColor);
  img.drawLine(image, x1: 256, y1: 141, x2: 416, y2: 261, color: emeraldColor);
  img.drawLine(image, x1: 256, y1: 142, x2: 416, y2: 262, color: emeraldColor);

  // Horizontal cantilever terrace
  img.fillRect(image, x1: 140, y1: 258, x2: 372, y2: 270, color: whiteSlate);

  // Lower pavilion glass box
  img.fillRect(image, x1: 160, y1: 270, x2: 352, y2: 380, color: darkEmerald);
  img.drawRect(image, x1: 160, y1: 270, x2: 352, y2: 380, color: emeraldColor);

  // Vertical structural columns
  img.drawLine(image, x1: 200, y1: 270, x2: 200, y2: 380, color: whiteSlate);
  img.drawLine(image, x1: 256, y1: 270, x2: 256, y2: 380, color: whiteSlate);
  img.drawLine(image, x1: 312, y1: 270, x2: 312, y2: 380, color: whiteSlate);

  // Compass azimuth indicator needle
  img.drawLine(image, x1: 256, y1: 80, x2: 256, y2: 140, color: goldColor);
  img.drawLine(image, x1: 255, y1: 80, x2: 255, y2: 140, color: goldColor);
  img.drawLine(image, x1: 257, y1: 80, x2: 257, y2: 140, color: goldColor);

  File('assets/icons/app_icon.png').writeAsBytesSync(img.encodePng(image));
}

void generateVillaCourtyard() {
  const width = 800;
  const height = 500;
  final image = img.Image(width: width, height: height);

  // Sky dusk gradient
  for (int y = 0; y < 280; y++) {
    final t = y / 280.0;
    final r = (18 + 25 * t).round();
    final g = (28 + 35 * t).round();
    final b = (52 + 40 * t).round();
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Ground / courtyard pool area
  final poolColor = img.ColorRgb8(6, 78, 59);
  final poolHighlight = img.ColorRgb8(16, 185, 129);
  final terraceStone = img.ColorRgb8(51, 65, 85);
  final villaWall = img.ColorRgb8(241, 245, 249);
  final glassWarm = img.ColorRgb8(254, 240, 138);
  final woodTimber = img.ColorRgb8(180, 83, 9);

  // Stone terrace ground
  img.fillRect(image, x1: 0, y1: 280, x2: width, y2: height, color: terraceStone);

  // Reflection infinity pool
  img.fillRect(image, x1: 150, y1: 360, x2: 650, y2: 480, color: poolColor);
  img.drawRect(image, x1: 148, y1: 358, x2: 652, y2: 482, color: poolHighlight);

  // Villa building volume
  img.fillRect(image, x1: 100, y1: 140, x2: 700, y2: 340, color: villaWall);

  // Massive architectural glass openings with interior warm glow
  img.fillRect(image, x1: 140, y1: 170, x2: 380, y2: 330, color: glassWarm);
  img.fillRect(image, x1: 420, y1: 170, x2: 660, y2: 330, color: glassWarm);

  // Timber cantilever louvers
  for (int y = 180; y < 330; y += 18) {
    img.drawLine(image, x1: 140, y1: y, x2: 240, y2: y, color: woodTimber);
  }

  // Floating concrete cantilever roof slab
  img.fillRect(image, x1: 80, y1: 120, x2: 720, y2: 145, color: img.ColorRgb8(30, 41, 59));

  // Soft reflection ripple in the pool
  for (int y = 370; y < 470; y += 12) {
    img.drawLine(image, x1: 200, y1: y, x2: 600, y2: y, color: img.ColorRgb8(20, 184, 166));
  }

  File('assets/images/villa_courtyard.png').writeAsBytesSync(img.encodePng(image));
}

void generatePenthouseLoft() {
  const width = 800;
  const height = 500;
  final image = img.Image(width: width, height: height);

  // Night city skyline gradient
  for (int y = 0; y < height; y++) {
    final t = y / height;
    final r = (10 + 20 * t).round();
    final g = (15 + 25 * t).round();
    final b = (35 + 40 * t).round();
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // City skyscrapers in background
  final towerColor = img.ColorRgb8(30, 41, 59);
  final towerLight = img.ColorRgb8(250, 204, 21);
  final towers = [
    [40, 180, 120],
    [140, 130, 220],
    [240, 160, 310],
    [480, 140, 560],
    [580, 110, 670],
    [690, 190, 770],
  ];

  for (final t in towers) {
    img.fillRect(image, x1: t[0], y1: t[1], x2: t[2], y2: height, color: towerColor);
    for (int ly = t[1] + 15; ly < 400; ly += 20) {
      for (int lx = t[0] + 10; lx < t[2] - 10; lx += 15) {
        if ((lx + ly) % 3 != 0) {
          img.fillRect(image, x1: lx, y1: ly, x2: lx + 4, y2: ly + 6, color: towerLight);
        }
      }
    }
  }

  // Foreground double-height loft window frame
  final frameColor = img.ColorRgb8(15, 23, 42);
  final metalBeams = img.ColorRgb8(71, 85, 105);
  // Perimeter frames
  img.fillRect(image, x1: 0, y1: 0, x2: width, y2: 30, color: frameColor);
  img.fillRect(image, x1: 0, y1: 420, x2: width, y2: height, color: frameColor);
  img.fillRect(image, x1: 0, y1: 0, x2: 40, y2: height, color: frameColor);
  img.fillRect(image, x1: width - 40, y1: 0, x2: width, y2: height, color: frameColor);

  // Architectural mullions
  img.drawLine(image, x1: 270, y1: 30, x2: 270, y2: 420, color: metalBeams);
  img.drawLine(image, x1: 530, y1: 30, x2: 530, y2: 420, color: metalBeams);
  img.drawLine(image, x1: 40, y1: 220, x2: width - 40, y2: 220, color: metalBeams);

  // Interior herringbone parquet floor hint
  img.fillRect(image, x1: 40, y1: 420, x2: width - 40, y2: height, color: img.ColorRgb8(120, 53, 15));

  File('assets/images/penthouse_loft.png').writeAsBytesSync(img.encodePng(image));
}

void generateCommercialHub() {
  const width = 800;
  const height = 500;
  final image = img.Image(width: width, height: height);

  // Twilight sky
  for (int y = 0; y < height; y++) {
    final t = y / height;
    final r = (15 + 20 * t).round();
    final g = (25 + 30 * t).round();
    final b = (45 + 50 * t).round();
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Futuristic commercial building
  final facadeBlue = img.ColorRgb8(14, 116, 144);
  final facadeGlass = img.ColorRgb8(6, 182, 212);
  final terraceGarden = img.ColorRgb8(16, 185, 129);
  final frameSteel = img.ColorRgb8(203, 213, 225);

  // Stepped tower block 1
  img.fillRect(image, x1: 180, y1: 80, x2: 440, y2: 440, color: facadeBlue);
  // Stepped tower block 2
  img.fillRect(image, x1: 440, y1: 140, x2: 640, y2: 440, color: img.ColorRgb8(3, 105, 161));

  // Sky garden terraces
  img.fillRect(image, x1: 440, y1: 130, x2: 640, y2: 145, color: terraceGarden);
  img.fillRect(image, x1: 180, y1: 70, x2: 440, y2: 85, color: terraceGarden);

  // Curtain wall grid lines
  for (int y = 90; y < 440; y += 22) {
    img.drawLine(image, x1: 180, y1: y, x2: 440, y2: y, color: frameSteel);
  }
  for (int x = 200; x < 440; x += 30) {
    img.drawLine(image, x1: x, y1: 80, x2: x, y2: 440, color: facadeGlass);
  }

  for (int y = 150; y < 440; y += 22) {
    img.drawLine(image, x1: 440, y1: y, x2: 640, y2: y, color: frameSteel);
  }
  for (int x = 460; x < 640; x += 30) {
    img.drawLine(image, x1: x, y1: 140, x2: x, y2: 440, color: facadeGlass);
  }

  // Plaza street level
  img.fillRect(image, x1: 0, y1: 440, x2: width, y2: height, color: img.ColorRgb8(30, 41, 59));
  for (int x = 40; x < width; x += 80) {
    img.drawCircle(image, x: x, y: 448, radius: 12, color: terraceGarden);
  }

  File('assets/images/commercial_hub.png').writeAsBytesSync(img.encodePng(image));
}

void generateSmartTownhouse() {
  const width = 800;
  const height = 500;
  final image = img.Image(width: width, height: height);

  // Clean ambient background
  for (int y = 0; y < height; y++) {
    final t = y / height;
    final r = (20 + 15 * t).round();
    final g = (25 + 20 * t).round();
    final b = (35 + 25 * t).round();
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Modern Dark Brick and Timber Townhouse
  final darkBrick = img.ColorRgb8(41, 37, 36);
  final timber = img.ColorRgb8(194, 65, 12);
  final stoneEntry = img.ColorRgb8(226, 232, 240);
  final glassGlow = img.ColorRgb8(254, 243, 199);

  // Main townhouse structure
  img.fillRect(image, x1: 220, y1: 90, x2: 580, y2: 430, color: darkBrick);

  // Large 2nd floor window with timber screens
  img.fillRect(image, x1: 260, y1: 130, x2: 540, y2: 240, color: glassGlow);
  for (int x = 260; x < 380; x += 10) {
    img.drawLine(image, x1: x, y1: 130, x2: x, y2: 240, color: timber);
  }

  // Ground floor modern pivot door & courtyard entryway
  img.fillRect(image, x1: 260, y1: 280, x2: 420, y2: 430, color: glassGlow);
  img.fillRect(image, x1: 450, y1: 280, x2: 540, y2: 430, color: timber);

  // Cantilever canopy over entry
  img.fillRect(image, x1: 240, y1: 265, x2: 560, y2: 280, color: stoneEntry);

  // Pathway
  img.fillRect(image, x1: 0, y1: 430, x2: width, y2: height, color: img.ColorRgb8(15, 23, 42));

  File('assets/images/smart_townhouse.png').writeAsBytesSync(img.encodePng(image));
}

void generateBlueprintFloorplan() {
  const width = 800;
  const height = 600;
  final image = img.Image(width: width, height: height);

  // Cyan architectural blueprint paper
  final bgBlue = img.ColorRgb8(15, 34, 64);
  final gridLine = img.ColorRgb8(24, 52, 94);
  final wallLine = img.ColorRgb8(255, 255, 255);
  final dimLine = img.ColorRgb8(56, 189, 248);
  final textWhite = img.ColorRgb8(241, 245, 249);
  final highlightZone = img.ColorRgb8(20, 83, 45);

  // Background
  img.fill(image, color: bgBlue);

  // Blueprint grid 20x20
  for (int x = 0; x < width; x += 25) {
    img.drawLine(image, x1: x, y1: 0, x2: x, y2: height, color: gridLine);
  }
  for (int y = 0; y < height; y += 25) {
    img.drawLine(image, x1: 0, y1: y, x2: width, y2: y, color: gridLine);
  }

  // Exterior walls (thick)
  void drawThickLine(int x1, int y1, int x2, int y2) {
    img.drawLine(image, x1: x1, y1: y1, x2: x2, y2: y2, color: wallLine);
    img.drawLine(image, x1: x1 + 1, y1: y1 + 1, x2: x2 + 1, y2: y2 + 1, color: wallLine);
    img.drawLine(image, x1: x1 - 1, y1: y1 - 1, x2: x2 - 1, y2: y2 - 1, color: wallLine);
  }

  // Living Atrium room zone
  img.fillRect(image, x1: 100, y1: 100, x2: 450, y2: 350, color: img.ColorRgb8(20, 48, 88));
  // Master Suite room zone
  img.fillRect(image, x1: 450, y1: 100, x2: 700, y2: 350, color: highlightZone);
  // Gourmet Kitchen & Dining
  img.fillRect(image, x1: 100, y1: 350, x2: 450, y2: 520, color: img.ColorRgb8(20, 48, 88));
  // Terrace & Pool Deck
  img.fillRect(image, x1: 450, y1: 350, x2: 700, y2: 520, color: img.ColorRgb8(12, 74, 96));

  // Perimeter walls
  drawThickLine(100, 100, 700, 100);
  drawThickLine(700, 100, 700, 520);
  drawThickLine(700, 520, 100, 520);
  drawThickLine(100, 520, 100, 100);

  // Internal partition walls
  drawThickLine(450, 100, 450, 520);
  drawThickLine(100, 350, 700, 350);

  // Door openings
  img.drawLine(image, x1: 450, y1: 200, x2: 450, y2: 250, color: bgBlue);
  img.drawLine(image, x1: 240, y1: 350, x2: 290, y2: 350, color: bgBlue);

  // Dimension lines with arrows
  img.drawLine(image, x1: 80, y1: 100, x2: 80, y2: 520, color: dimLine);
  img.drawLine(image, x1: 100, y1: 80, x2: 700, y2: 80, color: dimLine);

  // North arrow symbol
  img.drawLine(image, x1: 740, y1: 80, x2: 740, y2: 40, color: textWhite);
  img.drawLine(image, x1: 740, y1: 40, x2: 730, y2: 55, color: textWhite);
  img.drawLine(image, x1: 740, y1: 40, x2: 750, y2: 55, color: textWhite);

  File('assets/images/blueprint_floorplan.png').writeAsBytesSync(img.encodePng(image));
}

void generateAdvisorAvatar(String path, img.Color primary, img.Color secondary, String initials) {
  const size = 256;
  final image = img.Image(width: size, height: size);

  // Gradient circular background
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - 128;
      final dy = y - 128;
      if (dx * dx + dy * dy <= 124 * 124) {
        final t = (x + y) / (2 * size);
        image.setPixel(x, y, t < 0.5 ? primary : secondary);
      } else {
        image.setPixelRgb(x, y, 15, 23, 42); // slate background
      }
    }
  }

  // Draw clean vector head/shoulder silhouette
  final white = img.ColorRgb8(248, 250, 252);
  // Head
  img.drawCircle(image, x: 128, y: 100, radius: 42, color: white);
  // Shoulders arc
  for (int y = 145; y < 240; y++) {
    for (int x = 40; x < 216; x++) {
      final dx = (x - 128) / 80.0;
      final dy = (y - 200) / 55.0;
      if (dx * dx + dy * dy <= 1.0 && y >= 145) {
        image.setPixel(x, y, white);
      }
    }
  }

  // Verified badge in corner
  final gold = img.ColorRgb8(245, 158, 11);
  img.drawCircle(image, x: 200, y: 200, radius: 24, color: gold);
  img.drawCircle(image, x: 200, y: 200, radius: 22, color: img.ColorRgb8(15, 23, 42));
  // Star/checkmark
  img.drawLine(image, x1: 192, y1: 200, x2: 198, y2: 206, color: gold);
  img.drawLine(image, x1: 198, y1: 206, x2: 209, y2: 194, color: gold);

  File(path).writeAsBytesSync(img.encodePng(image));
}
