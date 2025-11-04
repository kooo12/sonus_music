class EqBand {
  final int band;
  final int center; // Hz (renamed from centerFrequency for consistency)
  final int minLevel; // dB
  final int maxLevel; // dB
  final int level; // dB current

  const EqBand({
    required this.band,
    required this.center,
    required this.minLevel,
    required this.maxLevel,
    this.level = 0,
  });

  EqBand copyWith({int? level}) => EqBand(
        band: band,
        center: center,
        minLevel: minLevel,
        maxLevel: maxLevel,
        level: level ?? this.level,
      );
}
