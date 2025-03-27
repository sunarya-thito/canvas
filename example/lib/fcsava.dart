import 'package:cassowary/cassowary.dart';

maina() {
  var solver = Solver();
  var aW = cm(150); // fixed: 150
  var bW = Param(0); // flex: 1
  var cW = cm(100); // fixed: 100
  var dW = Param(0); // flex: 2
  dW.context = '';

  var x = Param(0);
  var remainingSpace = Param(0);
  var flexUnit = Param(0);
  var actualWidth = Param(0);

  final gap = cm(20);
  final paddingLeft = cm(10);
  final paddingRight = cm(10);

  final totalWidth = cm(500);
  // final actualWidth = totalWidth - paddingLeft - paddingRight;

  // final remainingSpace = actualWidth - aW - cW - (gap * cm(3));
  // final flexUnit = remainingSpace / cm(1 + 2);

  // final usedWidth =
  //     Term(aW, 1) + gap + bW + gap + Term(cW, 1) + gap + dW;

  var result = solver.addConstraints([
    actualWidth.equals(totalWidth - paddingLeft - paddingRight),
    remainingSpace.equals(actualWidth - aW - cW - (gap * cm(3))),
    flexUnit.equals(remainingSpace / cm(1 + 2)),
    bW.equals(flexUnit),
    dW.equals(flexUnit * cm(2)),
    bW >= cm(150),
    bW <= cm(300),
    dW >= cm(150),
    dW <= cm(500),
    (aW + gap + bW + gap + cW + gap + dW + paddingLeft + paddingRight <=
        totalWidth)
      ..priority = Priority.weak,
    (x + aW + gap + bW + gap + cW + gap + dW + paddingRight).equals(totalWidth),
  ]);
  /*
  paddingLeft + aW + gap + bW + gap + cW + gap + dW + paddingRight = totalWidth
  aW = 150
  bW = flexUnit
  cW = 100
  dW = flexUnit * 2
  */

  var timer = Stopwatch()..start();
  solver.flushUpdates();
  timer.stop();
  print('Elapsed time: ${timer.elapsedMilliseconds}ms');

  print('remainingSpace: ${remainingSpace.value}');
  print('flexUnit: ${flexUnit.value}');
  print('aW: ${aW.value}');
  print('bW: ${bW.value}');
  print('cW: ${cW.value}');
  print('dW: ${dW.value}');
  print('x: ${x.value}');
  print('result: ${result.message}');
  // print('usedWidth: ${usedWidth.value}');
}
