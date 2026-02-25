import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:fair_share/services/ocr_service.dart';

class OCRServiceImpl implements OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  Future<List<ScannedItem>> scanBill(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    List<ScannedItem> items = [];
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        final priceRegex = RegExp(r'([$₹]\s?\d+[\.,]\d{2})|(\d+[\.,]\d{2})|([$₹]\s?\d+)|(\s\d{2,}$)');
        final matches = priceRegex.allMatches(text).toList();
        
        if (matches.isNotEmpty) {
          final lastMatch = matches.last;
          String priceStr = lastMatch.group(0)!;
          
          priceStr = priceStr.replaceAll(RegExp(r'[$₹\s]'), '').replaceAll(',', '.');
          final price = double.tryParse(priceStr) ?? 0;
          
          if (price >= 0) {
            String name = text.substring(0, lastMatch.start).trim();
            name = name.replaceFirst(RegExp(r'\s\d{1,2}$'), '').trim();
            name = name.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '').trim();
            
            if (name.isNotEmpty && name.length > 2) {
              if (!RegExp(r'^(ITEM|QTY|PRICE|TABLE|GUESTS|SERVER|CHECK|DATE)$', caseSensitive: false).hasMatch(name)) {
                items.add(ScannedItem(name: name, price: price));
              }
            }
          }
        }
      }
    }
    
    final falsePositives = [
      'total', 'subtotal', 'tax', 'discount', 'cgst', 'sgst', 'gst', 'bill', 
      'due', 'change', 'cash', 'card', 'visa', 'mastercard', 'balance', 'items',
      'guests', 'server', 'table', 'sequence', 'please', 'come back', 'id #'
    ];
    
    items.removeWhere((item) {
      final lowerName = item.name.toLowerCase();
      if (item.price == 0 && (lowerName.contains('*') || lowerName.contains('-'))) return true;
      return falsePositives.any((fp) => lowerName == fp || lowerName.contains(fp));
    });

    return items;
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}
