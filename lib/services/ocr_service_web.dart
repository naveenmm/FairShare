import 'package:fair_share/services/ocr_service.dart';

class OCRServiceImpl implements OCRService {
  @override
  Future<List<ScannedItem>> scanBill(String imagePath) async {
    // This will never be called on web as the button is hidden
    return [];
  }

  @override
  void dispose() {
    // No-op on web
  }
}
