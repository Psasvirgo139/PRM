import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product Pagination Calculation Tests', () {
    test('Total pages calculation handles various counts accurately', () {
      int calculateTotalPages(int totalItems, int pageSize) {
        if (totalItems <= 0) return 1;
        return (totalItems / pageSize).ceil();
      }

      expect(calculateTotalPages(32, 8), 4);
      expect(calculateTotalPages(33, 8), 5);
      expect(calculateTotalPages(7, 8), 1);
      expect(calculateTotalPages(0, 8), 1);
      expect(calculateTotalPages(32, 12), 3);
    });

    test('Start and End index calculations are correct for boundaries', () {
      int getStartIndex(int totalItems, int currentPage, int pageSize) {
        if (totalItems == 0) return 0;
        return (currentPage - 1) * pageSize + 1;
      }

      int getEndIndex(int totalItems, int currentPage, int pageSize) {
        final end = currentPage * pageSize;
        return end > totalItems ? totalItems : end;
      }

      // 32 items, page size 8
      expect(getStartIndex(32, 1, 8), 1);
      expect(getEndIndex(32, 1, 8), 8);

      expect(getStartIndex(32, 2, 8), 9);
      expect(getEndIndex(32, 2, 8), 16);

      expect(getStartIndex(32, 4, 8), 25);
      expect(getEndIndex(32, 4, 8), 32);

      // 33 items, page 5 with page size 8
      expect(getStartIndex(33, 5, 8), 33);
      expect(getEndIndex(33, 5, 8), 33);

      // Empty list
      expect(getStartIndex(0, 1, 8), 0);
      expect(getEndIndex(0, 1, 8), 0);
    });

    test('Pagination navigation flags function as expected', () {
      bool hasPrevious(int currentPage) => currentPage > 1;
      bool hasNext(int currentPage, int totalPages) => currentPage < totalPages;

      // First page of 4
      expect(hasPrevious(1), false);
      expect(hasNext(1, 4), true);

      // Middle page
      expect(hasPrevious(2), true);
      expect(hasNext(2, 4), true);

      // Last page of 4
      expect(hasPrevious(4), true);
      expect(hasNext(4, 4), false);

      // Single page
      expect(hasPrevious(1), false);
      expect(hasNext(1, 1), false);
    });
  });
}

