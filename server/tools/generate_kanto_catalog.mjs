import fs from "node:fs/promises";
import path from "node:path";

const root = process.argv[2];
if (!root) throw new Error("Usage: node generate_kanto_catalog.mjs <server-root>");

const outputDir = path.join(root, "data-canary", "lib", "pokemon", "species");
const monsterDir = path.join(root, "data-canary", "monster", "pokemon");
const cacheDir = path.join(root, "tools", "pokemon-data-cache", "pokeapi-v2");
const ids = Array.from({ length: 151 }, (_, index) => index + 1);
// The modern Thor assets reserve one stable contiguous Kanto range. Keeping
// lookType = 3000 + National Dex ID makes every server/client mapping
// deterministic and auditable.
const existingLooks = new Map(ids.map(id => [id, 3000 + id]));

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(monsterDir, { recursive: true });
await fs.mkdir(cacheDir, { recursive: true });

async function cachedJson(kind, idOrUrl) {
  const id = String(idOrUrl).match(/(\d+)\/?$/)?.[1] ?? String(idOrUrl);
  const file = path.join(cacheDir, `${kind}-${id}.json`);
  try {
    return JSON.parse(await fs.readFile(file, "utf8"));
  } catch {}
  const url = String(idOrUrl).startsWith("http")
    ? String(idOrUrl)
    : `https://pokeapi.co/api/v2/${kind}/${idOrUrl}/`;
  const response = await fetch(url, { headers: { "User-Agent": "Hakai-Engine-Catalog-Builder/1.0" } });
  if (!response.ok) throw new Error(`${response.status} fetching ${url}`);
  const data = await response.json();
  await fs.writeFile(file, `${JSON.stringify(data, null, 2)}\n`);
  return data;
}

async function mapLimit(values, limit, mapper) {
  const results = new Array(values.length);
  let cursor = 0;
  async function worker() {
    while (cursor < values.length) {
      const index = cursor++;
      results[index] = await mapper(values[index], index);
    }
  }
  await Promise.all(Array.from({ length: limit }, worker));
  return results;
}

const records = await mapLimit(ids, 10, async id => {
  const [pokemon, species] = await Promise.all([
    cachedJson("pokemon", id),
    cachedJson("pokemon-species", id),
  ]);
  return { id, pokemon, species };
});

const chainUrls = [...new Set(records.map(record => record.species.evolution_chain.url))];
const chains = await mapLimit(chainUrls, 8, url => cachedJson("evolution-chain", url));
const evolutionsBySpecies = new Map();

function speciesId(resource) {
  return Number(resource?.url?.match(/\/(\d+)\/?$/)?.[1]);
}

function walkEvolution(node) {
  const fromId = speciesId(node.species);
  for (const child of node.evolves_to ?? []) {
    const detail = child.evolution_details?.[0] ?? {};
    const evolutions = evolutionsBySpecies.get(fromId) ?? [];
    evolutions.push({
      speciesId: speciesId(child.species),
      method: detail.trigger?.name ?? "unknown",
      level: detail.min_level ?? null,
      item: detail.item?.name ?? detail.held_item?.name ?? null,
    });
    evolutionsBySpecies.set(fromId, evolutions);
    walkEvolution(child);
  }
}
for (const chain of chains) walkEvolution(chain.chain);

function titleCase(name) {
  return name.split("-").map(part => part ? part[0].toUpperCase() + part.slice(1) : part).join(" ");
}

function luaString(value) {
  return JSON.stringify(value);
}

function luaEvolution(evolution) {
  if (!evolution) return "nil";
  const fields = [`speciesId = ${evolution.speciesId}`, `method = ${luaString(evolution.method)}`];
  if (evolution.level != null) fields.push(`level = ${evolution.level}`);
  if (evolution.item) fields.push(`item = ${luaString(evolution.item)}`);
  return `{ ${fields.join(", ")} }`;
}

function luaEvolutions(evolutions) {
  if (!evolutions?.length) return "{}";
  return `{ ${evolutions.map(luaEvolution).join(", ")} }`;
}

const manifest = [];
for (const { id, pokemon, species } of records) {
  const stats = Object.fromEntries(pokemon.stats.map(entry => [entry.stat.name, entry.base_stat]));
  const types = pokemon.types.sort((a, b) => a.slot - b.slot).map(entry => entry.type.name);
  const femaleRate = species.gender_rate;
  const gender = femaleRate < 0
    ? { male: 0, female: 0, genderless: 1000 }
    : { female: femaleRate * 125, male: 1000 - femaleRate * 125, genderless: 0 };
  const fileName = `${String(id).padStart(3, "0")}_${pokemon.name.replaceAll("-", "_")}.lua`;
  const lookType = existingLooks.get(id) ?? 45;
  const placeholder = !existingLooks.has(id);
  const evolvesFrom = speciesId(species.evolves_from_species);
  const evolutions = evolutionsBySpecies.get(id) ?? [];
  const evolvesTo = evolutions.length > 0;
  const defaultLevel = id >= 144
    ? 50
    : !evolvesFrom && evolvesTo
      ? 5
      : evolvesFrom && evolvesTo
        ? 20
        : evolvesFrom
          ? 40
          : 20;
  const body = `return {
\tid = ${id},
\tname = ${luaString(titleCase(pokemon.name))},
\ttypes = { ${types.map(luaString).join(", ")} },
\tbaseStats = {
\t\thp = ${stats.hp},
\t\tattack = ${stats.attack},
\t\tdefense = ${stats.defense},
\t\tspecialAttack = ${stats["special-attack"]},
\t\tspecialDefense = ${stats["special-defense"]},
\t\tspeed = ${stats.speed},
\t},
\tgender = { male = ${gender.male}, female = ${gender.female}, genderless = ${gender.genderless} },
\tcatchRate = ${species.capture_rate},
\tbaseExperience = ${pokemon.base_experience ?? 0},
\t-- evolution keeps the first route for legacy consumers. New code must use evolutions.
\tevolution = ${luaEvolution(evolutions[0])},
\tevolutions = ${luaEvolutions(evolutions)},
\truntime = { placeholder = ${placeholder}, lookType = ${lookType}, level = ${defaultLevel} },
}
`;
  await fs.writeFile(path.join(outputDir, fileName), body);
  await fs.writeFile(
    path.join(monsterDir, `${pokemon.name.replaceAll("-", "_")}.lua`),
    `PokemonMonsterFactory.register(${id})\n`,
  );
  manifest.push(fileName);
}

const manifestBody = `-- Generated by tools/generate_kanto_catalog.mjs. Do not reorder manually.
return {
${manifest.map(file => `\t${luaString(file)},`).join("\n")}
}
`;
await fs.writeFile(path.join(outputDir, "kanto_catalog.lua"), manifestBody);
console.log(`Generated ${manifest.length} Kanto species in ${outputDir}`);
