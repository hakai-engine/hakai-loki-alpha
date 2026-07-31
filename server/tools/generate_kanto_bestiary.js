const fs = require("fs");
const path = require("path");

const speciesDir = process.argv[2];
const output = process.argv[3];
if (!speciesDir || !output) {
  throw new Error("usage: node generate_kanto_bestiary.js <species-dir> <output>");
}

const legendary = new Set([144, 145, 146, 150, 151]);
const safari = new Set([29,30,31,32,33,34,46,47,48,49,102,103,111,112,113,115,123,127,128]);
const tower = new Set([92,93,94,104,105]);
const powerPlant = new Set([25,26,81,82,100,101,125,145]);

function habitats(id, types) {
  const result = [];
  const add = value => { if (!result.includes(value)) result.push(value); };
  if (types.includes("water") || id === 131) add("waters");
  if (types.includes("rock") || types.includes("ground")) { add("caves"); add("mountains"); }
  if (types.includes("bug") || types.includes("grass")) add("forests");
  if (types.includes("flying") || types.includes("normal") || types.includes("poison")) add("routes");
  if (tower.has(id)) add("pokemon_tower");
  if (powerPlant.has(id)) add("power_plant");
  if (safari.has(id)) add("safari_zone");
  if (legendary.has(id)) add("legendary");
  if (!result.length) add("routes");
  return result;
}

const records = fs.readdirSync(speciesDir)
  .filter(file => /^\d{3}_.+\.lua$/.test(file))
  .map(file => {
    const source = fs.readFileSync(path.join(speciesDir, file), "utf8");
    const id = Number(source.match(/\bid\s*=\s*(\d+)/)[1]);
    const name = source.match(/\bname\s*=\s*"([^"]+)"/)[1];
    const typeBlock = source.match(/\btypes\s*=\s*\{([^}]+)\}/)[1];
    const types = [...typeBlock.matchAll(/"([^"]+)"/g)].map(match => match[1]);
    const lookTypeMatch = source.match(/\blookType\s*=\s*(\d+)/);
    if (!lookTypeMatch) throw new Error(`${file} has no runtime.lookType`);
    const lookType = Number(lookTypeMatch[1]);
    if (lookType <= 0) throw new Error(`${file} has invalid runtime.lookType ${lookType}`);
    return { id, name, lookType, types, habitats: habitats(id, types) };
  })
  .sort((a, b) => a.id - b.id);

if (records.length !== 151) throw new Error(`expected 151 species, got ${records.length}`);

const quoteList = values => `{ ${values.map(value => `"${value}"`).join(", ")} }`;
const lines = [
  "-- Generated from Odin's authoritative Kanto species catalog.",
  "-- Do not edit by hand; run tools/generate_kanto_bestiary.js.",
  "return {",
  ...records.map(record =>
    `  [${10000 + record.id}] = { id = ${record.id}, name = "${record.name}", lookType = ${record.lookType}, types = ${quoteList(record.types)}, habitats = ${quoteList(record.habitats)} },`
  ),
  "}",
  "",
];
fs.writeFileSync(output, lines.join("\n"));
