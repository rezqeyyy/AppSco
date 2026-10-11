import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Memotong bagian tengah foto supaya perbandingan lebar : tingginya sama dengan
/// [aspect], lalu menyimpannya sebagai PNG di folder yang sama.
/// Orientasi foto (EXIF) sudah diterapkan saat foto dibaca, jadi hasilnya selalu tegak.
/// Kalau pemotongan gagal, file aslinya yang dikembalikan.
Future<File> cropToAspect(File source, double aspect) async {
  try {
    final Uint8List bytes = await source.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final double width = image.width.toDouble();
    final double height = image.height.toDouble();
    double cropWidth = width;
    double cropHeight = height;
    if (width / height > aspect) {
      cropWidth = height * aspect;
    } else {
      cropHeight = width / aspect;
    }
    if (width - cropWidth < 2 && height - cropHeight < 2) {
      image.dispose();
      return source; // rasionya sudah sesuai
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final ui.Rect from =
        ui.Rect.fromLTWH((width - cropWidth) / 2, (height - cropHeight) / 2, cropWidth, cropHeight);
    final ui.Rect to = ui.Rect.fromLTWH(0, 0, cropWidth, cropHeight);
    canvas.drawImageRect(image, from, to, ui.Paint()..filterQuality = ui.FilterQuality.high);
    final ui.Image cropped =
        await recorder.endRecording().toImage(cropWidth.round(), cropHeight.round());
    final ByteData? data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();
    if (data == null) return source;

    final String base = source.path.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '');
    final File output = File('${base}_crop.png');
    await output.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return output;
  } catch (_) {
    return source;
  }
}