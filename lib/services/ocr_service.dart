import 'ocr_service_mobile.dart' if (dart.library.html) 'ocr_service_web.dart';

class ScannedItem {
  final String name;
  final double price;

  ScannedItem({required this.name, required this.price});
}

abstract class OCRService {
  factory OCRService() => OCRServiceImpl();

  Future<List<ScannedItem>> scanBill(String imagePath);
  void dispose();
}
