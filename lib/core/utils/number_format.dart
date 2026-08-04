/// 정수를 1000 단위 콤마로 포맷한다. (28000 -> "28,000")
String formatThousands(int n) {
  final neg = n < 0;
  final digits = n.abs().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return neg ? '-$digits' : digits;
}
