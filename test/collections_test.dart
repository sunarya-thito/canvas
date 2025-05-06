import 'package:canvas/src/collections.dart';
import 'package:flutter_test/flutter_test.dart';

List<T> _collectIterator<T>(Iterator<LinkedNode<T>> iterator) {
  final result = <T>[];
  while (iterator.moveNext()) {
    result.add(iterator.current.value);
  }
  return result;
}

void main() {
  group('LinkedNode - Complex Behavior', () {
    late LinkedNode<int> a, b, c, d;

    setUp(() {
      a = LinkedNode(1);
      b = LinkedNode(2);
      c = LinkedNode(3);
      d = LinkedNode(4);

      a.next = b;
      b.next = c;
      c.next = d;
    });

    test('Full forward iteration', () {
      expect(_collectIterator(a.toEndIterator), [1, 2, 3, 4]);
    });

    test('Full reverse iteration', () {
      expect(_collectIterator(d.toStartIterator), [4, 3, 2, 1]);
    });

    test('Correct values for reversed Iterable', () {
      expect(a.reversed.map((n) => n.value), [1]);
      expect(d.reversed.map((n) => n.value), [4, 3, 2, 1]);
    });

    test('Accessing first and last nodes from the middle', () {
      expect(c.first.value, 1);
      expect(b.last.value, 4);
    });

    test('getNextSibling and getPreviousSibling with count > 1', () {
      expect(a.getNextSibling(2)?.value, 3);
      expect(d.getPreviousSibling(3)?.value, 1);
    });

    test('Sibling containment', () {
      expect(b.siblingsContains(1), isTrue);
      expect(b.siblingsContains(3), isTrue);
      expect(b.siblingsContains(99), isFalse);
    });

    test('Counting siblings from middle', () {
      expect(b.countNextSiblings, 2);
      expect(b.countPreviousSiblings, 1);
    });

    test('copyWithNextSiblings produces a full deep copy forward', () {
      final copy = b.copyWithNextSiblings;
      expect(copy.value, 2);
      expect(copy.next!.value, 3);
      expect(copy.next!.next!.value, 4);
      expect(copy.next!.next!.next, isNull);
      expect(copy.previous, isNull);
    });

    test('copyWithPreviousSiblings produces a full deep copy backward', () {
      final copy = c.copyWithPreviousSiblings;
      expect(copy.value, 3);
      expect(copy.previous!.value, 2);
      expect(copy.previous!.previous!.value, 1);
      expect(copy.previous!.previous!.previous, isNull);
      expect(copy.next, isNull);
    });

    test('copy includes both directions properly from a middle node', () {
      final copy = b.copy;
      expect(copy.value, 2);
      expect(copy.previous?.value, 1);
      expect(copy.next?.value, 3);
    });

    test('Setting previous detaches old links and inserts correctly', () {
      final x = LinkedNode(0);
      b.previous = x;
      expect(b.previous?.value, 0);
      expect(x.next?.value, 2);
      expect(a.next, isNull); // old link detached
    });

    test('Setting next detaches old links and inserts correctly', () {
      final x = LinkedNode(5);
      b.next = x;
      expect(b.next?.value, 5);
      expect(x.previous?.value, 2);
      expect(c.previous, isNull);
    });

    test('Setting first inserts at the start and updates links', () {
      final x = LinkedNode(0);
      a.first = x;
      expect(a.first.value, 0);
      expect(x.next?.value, 1);
    });

    test('Setting last inserts at the end and updates links', () {
      final x = LinkedNode(5);
      d.last = x;
      expect(d.last.value, 5);
      expect(x.previous?.value, 4);
    });

    test('Circular reference check for previous throws', () {
      expect(() => a.previous = d, throwsException);
    });

    test('Circular reference check for first setter throws', () {
      expect(() => c.first = a, throwsException);
    });

    test('Circular reference check for last setter throws', () {
      expect(() => a.last = a, throwsException);
    });

    test('Iterator starting from null yields no elements', () {
      final emptyIterator = LinkedNodeIterator<int>(null, (n) => n.next);
      expect(emptyIterator.moveNext(), isFalse);
    });

    test('Manual iteration control', () {
      final iter = a.toEndIterator;
      expect(iter.moveNext(), isTrue);
      expect(iter.current.value, 1);
      expect(iter.moveNext(), isTrue);
      expect(iter.current.value, 2);
      expect(iter.moveNext(), isTrue);
      expect(iter.current.value, 3);
      expect(iter.moveNext(), isTrue);
      expect(iter.current.value, 4);
      expect(iter.moveNext(), isFalse);
    });
  });
}
