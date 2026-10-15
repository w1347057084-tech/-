class OrbitalOccupancy {
  const OrbitalOccupancy({required this.orbital, required this.electrons});

  final String orbital;
  final int electrons;

  static OrbitalOccupancy fromJson(Map<String, Object?> json) {
    return OrbitalOccupancy(
      orbital: json['orbital']?.toString() ?? '',
      electrons: (json['electrons'] as num?)?.toInt() ?? -1,
    );
  }

  Map<String, Object?> toJson() => {'orbital': orbital, 'electrons': electrons};
}

class ElectronConfiguration {
  const ElectronConfiguration({
    required this.nobleGasCore,
    required this.orbitals,
  });

  final String? nobleGasCore;
  final List<OrbitalOccupancy> orbitals;

  static const Map<String, int> _nobleGasElectrons = {
    'He': 2,
    'Ne': 10,
    'Ar': 18,
    'Kr': 36,
    'Xe': 54,
    'Rn': 86,
  };

  int get totalElectrons {
    final core = nobleGasCore == null ? 0 : _nobleGasElectrons[nobleGasCore]!;
    return core +
        orbitals.fold<int>(0, (sum, orbital) => sum + orbital.electrons);
  }

  String get compactText {
    final buffer = StringBuffer();
    if (nobleGasCore != null) {
      buffer.write('[$nobleGasCore]');
    }
    for (final orbital in orbitals) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer
        ..write(orbital.orbital)
        ..write(orbital.electrons);
    }
    return buffer.toString();
  }

  bool get isStructurallyValid {
    if (nobleGasCore != null && !_nobleGasElectrons.containsKey(nobleGasCore)) {
      return false;
    }
    const capacities = {'s': 2, 'p': 6, 'd': 10, 'f': 14};
    final seen = <String>{};
    for (final orbital in orbitals) {
      if (!RegExp(r'^[1-7][spdf]$').hasMatch(orbital.orbital)) {
        return false;
      }
      if (!seen.add(orbital.orbital)) {
        return false;
      }
      final capacity = capacities[orbital.orbital[1]]!;
      if (orbital.electrons < 1 || orbital.electrons > capacity) {
        return false;
      }
    }
    return orbitals.isNotEmpty;
  }

  static ElectronConfiguration fromJson(Map<String, Object?> json) {
    final core = json['nobleGasCore']?.toString();
    final orbitals = json['orbitals'];
    return ElectronConfiguration(
      nobleGasCore: core == null || core.isEmpty ? null : core,
      orbitals: orbitals is List<Object?>
          ? orbitals
                .map(
                  (item) =>
                      OrbitalOccupancy.fromJson(item! as Map<String, Object?>),
                )
                .toList(growable: false)
          : const [],
    );
  }

  static ElectronConfiguration parse(String text) {
    var remaining = text.trim();
    String? core;
    final coreMatch = RegExp(r'^\[([A-Za-z]+)\]').firstMatch(remaining);
    if (coreMatch != null) {
      core = coreMatch.group(1);
      remaining = remaining.substring(coreMatch.end).trim();
    }

    final orbitals = <OrbitalOccupancy>[];
    for (final match in RegExp(r'([1-7][spdf])(\d+)').allMatches(remaining)) {
      orbitals.add(
        OrbitalOccupancy(
          orbital: match.group(1)!,
          electrons: int.parse(match.group(2)!),
        ),
      );
    }
    return ElectronConfiguration(
      nobleGasCore: core,
      orbitals: List.unmodifiable(orbitals),
    );
  }

  Map<String, Object?> toJson() => {
    'nobleGasCore': nobleGasCore,
    'orbitals': orbitals.map((orbital) => orbital.toJson()).toList(),
  };
}
