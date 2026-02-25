import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ScannedItem {
  final String name;
  final double price;

  ScannedItem({required this.name, required this.price});
}

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<List<ScannedItem>> scanBill(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    List<ScannedItem> items = [];
    
    // Improved strategy: 
    // 1. Identify prices (usually at the end of the line)
    // 2. Extract item name by removing quantity columns and price
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        // Regex for price:
        // - Looks for currency symbols ($ or ₹) followed by numbers
        // - Or just numbers with exactly 2 decimal places at the end
        // - Or any significant number at the end
        final priceRegex = RegExp(r'([$₹]\s?\d+[\.,]\d{2})|(\d+[\.,]\d{2})|([$₹]\s?\d+)|(\s\d{2,}$)');
        final matches = priceRegex.allMatches(text).toList();
        
        if (matches.isNotEmpty) {
          final lastMatch = matches.last;
          String priceStr = lastMatch.group(0)!;
          
          // Clean the price string
          priceStr = priceStr.replaceAll(RegExp(r'[$₹\s]'), '').replaceAll(',', '.');
          final price = double.tryParse(priceStr) ?? 0;
          
          if (price >= 0) { // Keep 0.00 items as they might be indicators
            String name = text.substring(0, lastMatch.start).trim();
            
            // Further clean name:
            // 1. Remove quantities (often a single digit before the price)
            // Example: "Pizza 1 $10.00" -> "Pizza"
            name = name.replaceFirst(RegExp(r'\s\d{1,2}$'), '').trim();
            
            // 2. Remove leading/trailing symbols (*, -, etc)
            name = name.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '').trim();
            
            if (name.isNotEmpty && name.length > 2) {
              // Ignore lines that look like headers or specific receipt noise
              if (!RegExp(r'^(ITEM|QTY|PRICE|TABLE|GUESTS|SERVER|CHECK|DATE)$', caseSensitive: false).hasMatch(name)) {
                items.add(ScannedItem(name: name, price: price));
              }
            }
          }
        }
      }
    }
    
    // Final Cleanup: Filter based on specific keywords
    final falsePositives = [
      'total', 'subtotal', 'tax', 'discount', 'cgst', 'sgst', 'gst', 'bill', 
      'due', 'change', 'cash', 'card', 'visa', 'mastercard', 'balance', 'items',
      'guests', 'server', 'table', 'sequence', 'please', 'come back', 'id #'
    ];
    
    items.removeWhere((item) {
      final lowerName = item.name.toLowerCase();
      // Remove zero-price items that look like section headers (e.g., ***APPS***)
      if (item.price == 0 && (lowerName.contains('*') || lowerName.contains('-'))) return true;
      return falsePositives.any((fp) => lowerName == fp || lowerName.contains(fp));
    });

    return items;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
