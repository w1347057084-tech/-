import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { CORE_ROWS } from './element_core.mjs';
import { PHYSICAL_ROWS } from './element_physical.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');

function rows(text) {
  return text
    .trim()
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function nullableNumber(value) {
  if (value === '-' || value === '') return null;
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) throw new Error(`Invalid number: ${value}`);
  return parsed;
}

function nullableString(value) {
  return value === '-' || value === '' ? null : value;
}

function parseCore() {
  return rows(CORE_ROWS).map((line) => {
    const fields = line.split('|');
    if (fields.length !== 10) {
      throw new Error(`Core row should have 10 fields: ${line}`);
    }
    const [
      atomicNumber,
      symbol,
      nameZh,
      nameEn,
      atomicMass,
      period,
      group,
      category,
      block,
      electronConfiguration,
    ] = fields;
    return {
      atomicNumber: Number(atomicNumber),
      symbol,
      nameZh,
      nameEn,
      atomicMass,
      period: Number(period),
      group: group === '' ? null : Number(group),
      category,
      block,
      electronConfiguration,
    };
  });
}

function parsePhysical() {
  const map = new Map();
  for (const line of rows(PHYSICAL_ROWS)) {
    const fields = line.split('|');
    if (fields.length !== 12) {
      throw new Error(`Physical row should have 12 fields: ${line}`);
    }
    const [
      atomicNumber,
      phaseAtStp,
      density,
      meltingPointK,
      boilingPointK,
      electronegativityPauling,
      atomicRadiusPm,
      oxidationStates,
      discoveryYear,
      discoverer,
      uses,
      notes,
    ] = fields;
    map.set(Number(atomicNumber), {
      phaseAtStp,
      density: nullableNumber(density),
      meltingPointK: nullableNumber(meltingPointK),
      boilingPointK: nullableNumber(boilingPointK),
      electronegativityPauling: nullableNumber(electronegativityPauling),
      atomicRadiusPm: nullableNumber(atomicRadiusPm),
      oxidationStates: oxidationStates === '-' ? '' : oxidationStates,
      discoveryYear: nullableNumber(discoveryYear),
      discoverer: nullableString(discoverer),
      uses: nullableString(uses),
      notes: nullableString(notes),
    });
  }
  return map;
}

const nobleGasShells = {
  He: [2],
  Ne: [2, 8],
  Ar: [2, 8, 8],
  Kr: [2, 8, 18, 8],
  Xe: [2, 8, 18, 18, 8],
  Rn: [2, 8, 18, 32, 18, 8],
};

function calculateShellDistribution(configuration) {
  const coreMatch = configuration.match(/^\[([A-Za-z]+)\]/);
  let remaining = configuration;
  let shells = [];
  if (coreMatch) {
    const core = nobleGasShells[coreMatch[1]];
    if (!core) throw new Error(`Unknown noble gas core: ${coreMatch[1]}`);
    shells = [...core];
    remaining = remaining.slice(coreMatch[0].length);
  }

  const orbitalPattern = /([1-7][spdf])(\d+)/g;
  let match;
  let matches = 0;
  while ((match = orbitalPattern.exec(remaining)) !== null) {
    matches += 1;
    const principal = Number(match[1][0]);
    const electrons = Number(match[2]);
    while (shells.length < principal) shells.push(0);
    shells[principal - 1] += electrons;
  }

  const expectedText = remaining.replace(/\s/g, '');
  const matchedText = [...remaining.matchAll(orbitalPattern)]
    .map((item) => item[0])
    .join('');
  if (matches === 0 || expectedText !== matchedText) {
    throw new Error(`Unable to parse electron configuration: ${configuration}`);
  }
  return shells;
}

function valenceConfiguration(configuration) {
  return configuration.replace(/^\[[A-Za-z]+\]\s*/, '').trim();
}

function configurationData(configuration) {
  const coreMatch = configuration.match(/^\[([A-Za-z]+)\]/);
  const remaining = coreMatch
    ? configuration.slice(coreMatch[0].length).trim()
    : configuration;
  const orbitals = [...remaining.matchAll(/([1-7][spdf])(\d+)/g)].map(
    (match) => ({
      orbital: match[1],
      electrons: Number(match[2]),
    }),
  );
  return {
    nobleGasCore: coreMatch ? coreMatch[1] : null,
    orbitals,
  };
}

function displayCoordinate(atomicNumber, period, group, category) {
  if (category === 'lanthanide') {
    return { displayRow: 9, displayColumn: 3 + (atomicNumber - 57) };
  }
  if (category === 'actinide') {
    return { displayRow: 10, displayColumn: 3 + (atomicNumber - 89) };
  }
  return { displayRow: period, displayColumn: group };
}

function validate(elements) {
  if (elements.length !== 118) {
    throw new Error(`Expected 118 elements, got ${elements.length}`);
  }
  const numbers = new Set();
  const symbols = new Set();
  const coordinates = new Set();
  for (const element of elements) {
    if (element.atomicNumber < 1 || element.atomicNumber > 118) {
      throw new Error(`Invalid atomic number: ${element.atomicNumber}`);
    }
    if (numbers.has(element.atomicNumber)) {
      throw new Error(`Duplicate atomic number: ${element.atomicNumber}`);
    }
    numbers.add(element.atomicNumber);
    if (symbols.has(element.symbol)) {
      throw new Error(`Duplicate symbol: ${element.symbol}`);
    }
    symbols.add(element.symbol);
    const coordinate = `${element.displayRow}:${element.displayColumn}`;
    if (coordinates.has(coordinate)) {
      throw new Error(`Coordinate collision at ${coordinate}`);
    }
    coordinates.add(coordinate);
    const shellTotal = element.shellDistribution.reduce((sum, value) => sum + value, 0);
    if (shellTotal !== element.atomicNumber) {
      throw new Error(
        `${element.symbol} shell total ${shellTotal} does not match atomic number ${element.atomicNumber}`,
      );
    }
    let structuredCompact = element.electronConfigurationData.nobleGasCore
      ? `[${element.electronConfigurationData.nobleGasCore}]`
      : '';
    for (const orbital of element.electronConfigurationData.orbitals) {
      if (structuredCompact) structuredCompact += ' ';
      structuredCompact += `${orbital.orbital}${orbital.electrons}`;
    }
    if (
      structuredCompact.replace(/\s/g, '') !==
        element.electronConfiguration.replace(/\s/g, '') ||
      element.electronConfigurationData.orbitals.some(
        (orbital) =>
          !/^[1-7][spdf]$/.test(orbital.orbital) ||
          orbital.electrons < 1 ||
          orbital.electrons >
            ({ s: 2, p: 6, d: 10, f: 14 }[orbital.orbital[1]] ?? 0),
      )
    ) {
      throw new Error(`${element.symbol} has invalid structured electron data`);
    }
    if (
      new Set(
        element.electronConfigurationData.orbitals.map(
          (orbital) => orbital.orbital,
        ),
      ).size !== element.electronConfigurationData.orbitals.length
    ) {
      throw new Error(`${element.symbol} has duplicate electron orbitals`);
    }
    const valenceCompact = element.valenceConfigurationData.orbitals
      .map((orbital) => `${orbital.orbital}${orbital.electrons}`)
      .join(' ');
    if (valenceCompact.replace(/\s/g, '') !== element.valenceConfiguration.replace(/\s/g, '')) {
      throw new Error(`${element.symbol} has invalid valence structure`);
    }
    if (element.displayColumn < 1 || element.displayColumn > 18) {
      throw new Error(`${element.symbol} has invalid display column`);
    }
    if (![1, 2, 3, 4, 5, 6, 7, 9, 10].includes(element.displayRow)) {
      throw new Error(`${element.symbol} has invalid display row`);
    }
  }
  for (let number = 1; number <= 118; number += 1) {
    if (!numbers.has(number)) throw new Error(`Missing element ${number}`);
  }
}

const core = parseCore();
const physical = parsePhysical();
if (physical.size !== 118) {
  throw new Error(`Expected 118 physical records, got ${physical.size}`);
}

const elements = core.map((element) => {
  const properties = physical.get(element.atomicNumber);
  if (!properties) {
    throw new Error(`Missing physical data for ${element.symbol}`);
  }
  const shellDistribution = calculateShellDistribution(element.electronConfiguration);
  const coordinate = displayCoordinate(
    element.atomicNumber,
    element.period,
    element.group,
    element.category,
  );
  if (coordinate.displayColumn == null) {
    throw new Error(`Missing display coordinate for ${element.symbol}`);
  }
  const representativeMass = element.atomicMass.match(/^\[(\d+)\]$/);
  return {
    atomicMassType: representativeMass
      ? 'representativeMassNumber'
      : 'standardAtomicWeight',
    representativeMassNumber: representativeMass
      ? Number(representativeMass[1])
      : null,
    valenceConfiguration: valenceConfiguration(element.electronConfiguration),
    valenceConfigurationData: configurationData(
      valenceConfiguration(element.electronConfiguration),
    ),
    electronConfigurationData: configurationData(element.electronConfiguration),
    ...element,
    ...coordinate,
    ...properties,
    densityUnit: properties.phaseAtStp === '气态' ? 'g/L (0°C, 101.325 kPa)' : 'g/cm³',
    shellDistribution,
  };
});

validate(elements.sort((a, b) => a.atomicNumber - b.atomicNumber));

const outputPath = path.join(projectRoot, 'assets', 'data', 'elements.json');
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(elements, null, 2)}\n`, 'utf8');
console.log(`Generated ${elements.length} elements at ${outputPath}`);
