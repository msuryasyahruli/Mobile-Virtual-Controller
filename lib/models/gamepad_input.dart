/// Model data lengkap untuk seluruh state tombol dan axis gamepad.
class GamepadInput {
  final bool a;
  final bool b;
  final bool x;
  final bool y;
  final bool lb;
  final bool rb;
  final bool start;
  final bool select;
  final bool l3;
  final bool r3;
  final bool dpadUp;
  final bool dpadDown;
  final bool dpadLeft;
  final bool dpadRight;

  final double lx;
  final double ly;
  final double rx;
  final double ry;
  final double lt;
  final double rt;

  /// Membuat instance [GamepadInput] dengan nilai default netral.
  const GamepadInput({
    this.a = false,
    this.b = false,
    this.x = false,
    this.y = false,
    this.lb = false,
    this.rb = false,
    this.start = false,
    this.select = false,
    this.l3 = false,
    this.r3 = false,
    this.dpadUp = false,
    this.dpadDown = false,
    this.dpadLeft = false,
    this.dpadRight = false,
    this.lx = 0.0,
    this.ly = 0.0,
    this.rx = 0.0,
    this.ry = 0.0,
    this.lt = 0.0,
    this.rt = 0.0,
  });

  /// Mengembalikan salinan [GamepadInput] dengan field tertentu yang diperbarui.
  GamepadInput copyWith({
    bool? a,
    bool? b,
    bool? x,
    bool? y,
    bool? lb,
    bool? rb,
    bool? start,
    bool? select,
    bool? l3,
    bool? r3,
    bool? dpadUp,
    bool? dpadDown,
    bool? dpadLeft,
    bool? dpadRight,
    double? lx,
    double? ly,
    double? rx,
    double? ry,
    double? lt,
    double? rt,
  }) {
    return GamepadInput(
      a: a ?? this.a,
      b: b ?? this.b,
      x: x ?? this.x,
      y: y ?? this.y,
      lb: lb ?? this.lb,
      rb: rb ?? this.rb,
      start: start ?? this.start,
      select: select ?? this.select,
      l3: l3 ?? this.l3,
      r3: r3 ?? this.r3,
      dpadUp: dpadUp ?? this.dpadUp,
      dpadDown: dpadDown ?? this.dpadDown,
      dpadLeft: dpadLeft ?? this.dpadLeft,
      dpadRight: dpadRight ?? this.dpadRight,
      lx: lx != null ? _normalizeAxis(lx, -1.0, 1.0) : this.lx,
      ly: ly != null ? _normalizeAxis(ly, -1.0, 1.0) : this.ly,
      rx: rx != null ? _normalizeAxis(rx, -1.0, 1.0) : this.rx,
      ry: ry != null ? _normalizeAxis(ry, -1.0, 1.0) : this.ry,
      lt: lt != null ? _normalizeAxis(lt, 0.0, 1.0) : this.lt,
      rt: rt != null ? _normalizeAxis(rt, 0.0, 1.0) : this.rt,
    );
  }

  /// Mengonversi state gamepad menjadi Map JSON sesuai protokol server Python.
  Map<String, dynamic> toJson() {
    return {
      'type': 'gamepad',
      'buttons': {
        'A': a,
        'B': b,
        'X': x,
        'Y': y,
        'LB': lb,
        'RB': rb,
        'START': start,
        'SELECT': select,
        'L3': l3,
        'R3': r3,
        'DPAD_UP': dpadUp,
        'DPAD_DOWN': dpadDown,
        'DPAD_LEFT': dpadLeft,
        'DPAD_RIGHT': dpadRight,
      },
      'axes': {
        'LX': _normalizeAxis(lx, -1.0, 1.0),
        'LY': _normalizeAxis(ly, -1.0, 1.0),
        'RX': _normalizeAxis(rx, -1.0, 1.0),
        'RY': _normalizeAxis(ry, -1.0, 1.0),
        'LT': _normalizeAxis(lt, 0.0, 1.0),
        'RT': _normalizeAxis(rt, 0.0, 1.0),
      },
    };
  }

  /// Membulatkan dan membatasi nilai axis agar stabil dan bebas dari -0.0.
  static double _normalizeAxis(double value, double min, double max) {
    final clamped = value.clamp(min, max).toDouble();
    final rounded = (clamped * 1000).round() / 1000.0;
    return rounded == 0.0 ? 0.0 : rounded;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamepadInput &&
        other.a == a &&
        other.b == b &&
        other.x == x &&
        other.y == y &&
        other.lb == lb &&
        other.rb == rb &&
        other.start == start &&
        other.select == select &&
        other.l3 == l3 &&
        other.r3 == r3 &&
        other.dpadUp == dpadUp &&
        other.dpadDown == dpadDown &&
        other.dpadLeft == dpadLeft &&
        other.dpadRight == dpadRight &&
        other.lx == lx &&
        other.ly == ly &&
        other.rx == rx &&
        other.ry == ry &&
        other.lt == lt &&
        other.rt == rt;
  }

  @override
  int get hashCode => Object.hashAll([
        a,
        b,
        x,
        y,
        lb,
        rb,
        start,
        select,
        l3,
        r3,
        dpadUp,
        dpadDown,
        dpadLeft,
        dpadRight,
        lx,
        ly,
        rx,
        ry,
        lt,
        rt,
      ]);
}
