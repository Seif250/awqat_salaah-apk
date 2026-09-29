import 'dart:convert';
import 'dart:io';

void main() {
  int pagesWithLessLines = 0;
  for (int i = 1; i <= 604; i++) {
    final file = File('assets/data/qcf_pages/page-${i.toString().padLeft(3, '0')}.json');
    if (!file.existsSync()) continue;
    
    final jsonStr = file.readAsStringSync();
    final data = jsonDecode(jsonStr);
    
    final lines = data['lines'] as List<dynamic>;
    if (lines.length != 15) {
      if (i > 2) {
        print('Page $i has ${lines.length} lines');
        pagesWithLessLines++;
      }
    }
  }
  print('Total standard pages with != 15 lines: $pagesWithLessLines');
}
