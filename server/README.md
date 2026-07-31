# Odin — Hakai Engine Server

Odin é o servidor autoritativo do Hakai Engine. Ele combina o núcleo C++20 e
Lua do [OpenTibiaBR Canary](https://github.com/opentibiabr/canary) com os
sistemas Pokémon desenvolvidos para o Loki.

> Este componente pertence ao monorepo
> [`hakai-loki-alpha`](https://github.com/hakai-engine/hakai-loki-alpha).
> O cliente correspondente é o [Thor](../client/README.md).

## Responsabilidades

O Odin controla:

- contas, sessões, personagens e persistência;
- mapa, criaturas, NPCs e eventos;
- espécies, instâncias capturadas, nature, gênero e IVs;
- atributos, progressão, evolução e equipamentos;
- golpes, tipos, dano e políticas de combate;
- Team, summon, recall, faint e battle lock;
- corpse, captura, Capture Bag e Poké Balls;
- cura, Nurse Joy, viagem, surf e fly;
- roster sincronizado com o Thor.

O catálogo atual contém definições das 151 espécies de Kanto em
`data-canary/lib/pokemon/species/` e os MonsterTypes correspondentes em
`data-canary/monster/pokemon/`.

## Contrato de rede local

| Serviço | Endereço padrão | Uso |
|---|---|---|
| Login HTTP | `http://127.0.0.1:8088/login` | autenticação e lista de personagens |
| Game protocol | `127.0.0.1:7172` | conexão do Thor ao mundo |
| Login legado | `127.0.0.1:7171` | infraestrutura Canary, não é a entrada do perfil Hakai |

O perfil Hakai usa protocolo `15.25` e `authType = "session"`. O login-server
entrega ao Thor um token de sessão opaco e o endereço do mundo.

## Pré-requisitos

- compilador com suporte a C++20;
- CMake e Ninja;
- dependências descritas em `vcpkg.json`;
- MariaDB compatível com `schema.sql`;
- PowerShell para os utilitários locais do Hakai.

No Windows, prefira Developer PowerShell ou Developer Command Prompt do Visual
Studio, com MSVC e Ninja disponíveis no `PATH`.

## Configuração

Crie a configuração local, que é ignorada pelo Git:

```powershell
Copy-Item config.lua.dist config.lua
```

Revise pelo menos:

- conexão do banco de dados;
- `ip`;
- `gameProtocolPort`;
- `serverName`;
- `authType = "session"`;
- datapack e mapa usados pelo ambiente.

Nunca versione `config.lua`, `.env`, bancos, logs ou chaves privadas.

## Build

Windows Release:

```powershell
cmake --preset windows-release
cmake --build --preset windows-release --target canary
```

Linux Release:

```bash
cmake --preset linux-release
cmake --build --preset linux-release --target canary -j4
```

Consulte [`docs/development.md`](docs/development.md) e
[`docs/building/`](docs/building/) para detalhes do ambiente.

## Login-server local

O Odin fixa a origem e a toolchain do login-server em
`tools/login-server/login-server.lock.json`. Downloads e binários ficam em
`.hakai-runtime/`, fora do Git.

Instale, inicie e teste:

```powershell
.\tools\login-server\Install-HakaiLoginServer.ps1
.\tools\login-server\Start-HakaiLoginServer.ps1
.\tools\login-server\Test-HakaiLoginServer.ps1
```

Para encerrar:

```powershell
.\tools\login-server\Stop-HakaiLoginServer.ps1
```

Os scripts locais mantêm HTTP e gRPC ligados ao loopback. Não exponha o
login-server diretamente à internet. Um deployment remoto precisa de HTTPS em
um reverse proxy confiável, mantendo o gRPC privado.

## Testes

Configure e compile os testes nativos no Windows:

```powershell
cmake --preset windows-release-enabled-tests
cmake --build --preset windows-release-enabled-tests
ctest --test-dir build/windows-release-enabled-tests --output-on-failure
```

Os contratos Lua Pokémon podem ser executados isoladamente com LuaJIT:

```powershell
luajit tests/lua/test_pokemon_domain.lua
luajit tests/lua/test_pokemon_team.lua
luajit tests/lua/test_capture_bag.lua
luajit tests/lua/test_pokemon_roster_protocol.lua
luajit tests/lua/test_pokemon_native_moves.lua
luajit tests/lua/test_npc_messaging.lua
```

## Estrutura principal

```text
server/
├── src/                         # núcleo C++
├── data-canary/lib/pokemon/     # domínio e regras Pokémon
├── data-canary/monster/pokemon/ # MonsterTypes
├── data/                        # recursos compartilhados do Canary
├── tests/                       # testes C++ e Lua
├── tools/login-server/          # login HTTP local
├── schema.sql                   # estrutura inicial do banco
└── config.lua.dist              # configuração de referência
```

## Upstream e licença

Odin deriva do OpenTibiaBR Canary e preserva seus avisos, histórico de autoria
e licença. O código deste componente é distribuído conforme
[`LICENSE`](LICENSE), GPL-2.0.

Recursos e documentação upstream:

- [Canary](https://github.com/opentibiabr/canary)
- [Wiki OpenTibiaBR](https://github.com/opentibiabr/canary/wiki)
- [Documentação local](docs/README.md)
