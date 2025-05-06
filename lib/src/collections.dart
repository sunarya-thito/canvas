class _ReversedLinkedNodeIterable<T> with Iterable<LinkedNode<T>> {
  final LinkedNode<T> node;
  const _ReversedLinkedNodeIterable(this.node);

  @override
  Iterator<LinkedNode<T>> get iterator =>
      LinkedNodeIterator(node, LinkedNode._previousSibling);
}

class LinkedNode<T> with Iterable<LinkedNode<T>> {
  final T value;
  LinkedNode<T>? _previous;
  LinkedNode<T>? _next;

  LinkedNode(this.value);

  static LinkedNode<T>? _previousSibling<T>(LinkedNode<T> node) {
    return node._previous;
  }

  static LinkedNode<T>? _nextSibling<T>(LinkedNode<T> node) {
    return node._next;
  }

  Iterable<LinkedNode<T>> get reversed => _ReversedLinkedNodeIterable(this);

  @override
  Iterator<LinkedNode<T>> get iterator =>
      LinkedNodeIterator(first, _nextSibling);

  Iterator<LinkedNode<T>> get nextSiblingsIterator =>
      LinkedNodeIterator(_next, _nextSibling);

  Iterator<LinkedNode<T>> get previousSiblingsIterator =>
      LinkedNodeIterator(_previous, _previousSibling);

  Iterator<LinkedNode<T>> get toEndIterator =>
      LinkedNodeIterator(this, _nextSibling);

  Iterator<LinkedNode<T>> get toStartIterator =>
      LinkedNodeIterator(this, _previousSibling);

  bool nextSiblingsContains(T value) {
    LinkedNode<T>? current = _next;
    while (current != null) {
      if (current.value == value) return true;
      current = current._next;
    }
    return false;
  }

  bool previousSiblingsContains(T value) {
    LinkedNode<T>? current = _previous;
    while (current != null) {
      if (current.value == value) return true;
      current = current._previous;
    }
    return false;
  }

  bool siblingsContains(T value) {
    return nextSiblingsContains(value) || previousSiblingsContains(value);
  }

  int get countNextSiblings {
    int count = 0;
    LinkedNode<T>? current = this;
    while (current != null) {
      count++;
      current = current._next;
    }
    return count - 1; // Exclude the current node
  }

  int get countPreviousSiblings {
    int count = 0;
    LinkedNode<T>? current = this;
    while (current != null) {
      count++;
      current = current._previous;
    }
    return count - 1; // Exclude the current node
  }

  LinkedNode<T> get copyWithNextSiblings {
    LinkedNode<T>? currentFirstCopy;
    LinkedNode<T>? previousCopy;
    LinkedNode<T>? current = this;
    while (current != null) {
      var copy = LinkedNode<T>(current.value);
      currentFirstCopy ??= copy;
      previousCopy?.next = copy;
      current = current.next;
      previousCopy = copy;
    }
    return currentFirstCopy!;
  }

  LinkedNode<T> get copyWithPreviousSiblings {
    LinkedNode<T>? previousCopy;
    LinkedNode<T>? current = this;
    LinkedNode<T>? currentFirstCopy;
    while (current != null) {
      var copy = LinkedNode<T>(current.value);
      currentFirstCopy ??= copy;
      previousCopy?.previous = copy;
      current = current.previous;
      previousCopy = copy;
    }
    return currentFirstCopy!;
  }

  LinkedNode<T> get copy {
    var first = this.first;
    var countPrevious = first.countPreviousSiblings;
    var copyFirst = first.copyWithNextSiblings;
    var next = copyFirst.getNextSibling(countPrevious + 1);
    assert(next != null, 'next is null');
    return next!;
  }

  LinkedNode<T>? getNextSibling([int count = 1]) {
    LinkedNode<T>? current = this;
    for (int i = 0; i < count; i++) {
      var next = current?._next;
      if (next == null) {
        return null;
      }
      current = next;
    }
    return current;
  }

  LinkedNode<T>? getPreviousSibling([int count = 1]) {
    LinkedNode<T>? current = this;
    for (int i = 0; i < count; i++) {
      var previous = current?._previous;
      if (previous == null) {
        return null;
      }
      current = previous;
    }
    return current;
  }

  @override
  LinkedNode<T> get first {
    LinkedNode<T>? current = this;
    while (current?._previous != null) {
      current = current?._previous;
    }
    return current!;
  }

  @override
  LinkedNode<T> get last {
    LinkedNode<T>? current = this;
    while (current?._next != null) {
      current = current?._next;
    }
    return current!;
  }

  void _checkCircularReference(
      LinkedNode<T>? node, LinkedNodeDirection<T> cursor) {
    if (node == null) return;
    LinkedNode<T>? current = this;
    while (current != null) {
      if (current == node) {
        throw Exception('Circular reference detected!');
      }
      current = cursor(current);
    }
  }

  /// Insert the whole [node] thread at the start of this node.
  set first(LinkedNode<T> node) {
    _checkCircularReference(node, _previousSibling);
    var current = this.first;
    node._next?._previous = null;
    node._next = current;
    current._previous = node;
  }

  /// Insert the whole [node] thread at the end of this node.
  set last(LinkedNode<T> node) {
    _checkCircularReference(node, _nextSibling);

    var current = this.last;
    node._previous?._next = null;
    node._previous = current;
    current._next = node;
  }

  LinkedNode<T>? get previous => _previous;
  LinkedNode<T>? get next => _next;

  /// Prepend the whole [node] thread to this node.
  set previous(LinkedNode<T>? node) {
    _checkCircularReference(node, _nextSibling);

    if (node == null) {
      _previous?._next = null;
      _previous = null;
      return;
    }

    var last = node.last;
    _previous?._next = null;
    node._previous = _previous;
    last._next = this;
    _previous = last;
  }

  /// Append the whole [node] thread to this node.
  set next(LinkedNode<T>? node) {
    _checkCircularReference(node, _previousSibling);

    if (node == null) {
      _next?._previous = null;
      _next = null;
      return;
    }

    var first = node.first;
    _next?._previous = null;
    node._next = _next;
    first._previous = this;
    _next = first;
  }
}

typedef LinkedNodeDirection<T> = LinkedNode<T>? Function(LinkedNode<T> node);

class LinkedNodeIterator<T> implements Iterator<LinkedNode<T>> {
  final LinkedNode<T>? _firstNode;
  bool _first = true;
  LinkedNode<T>? _current;
  final LinkedNodeDirection<T> _cursor;

  LinkedNodeIterator(this._firstNode, this._cursor) : _current = _firstNode;

  @override
  LinkedNode<T> get current {
    assert(_current != null, 'No current node');
    return _current!;
  }

  @override
  bool moveNext() {
    if (_first) {
      _first = false;
      return _firstNode != null;
    }
    if (_current == null) return false;
    _current = _cursor(_current!);
    return _current != null;
  }
}
