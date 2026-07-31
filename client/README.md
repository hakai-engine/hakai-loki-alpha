# Thor — Hakai Engine Client

Thor é o cliente desktop do Hakai Engine. Ele deriva do
[OTClient Redemption](https://github.com/opentibiabr/otclient) e reúne a
renderização, a interface e os módulos client-side do PokéTibia Loki.

> Este componente pertence ao monorepo
> [`hakai-loki-alpha`](https://github.com/hakai-engine/hakai-loki-alpha).
> O servidor correspondente é o [Odin](../server/README.md).

## Integração com Odin

O perfil local está definido em `init.lua`:

| Parâmetro | Valor padrão |
|---|---|
| Login | `http://127.0.0.1:8088/login` |
| Protocolo | `15.25` |
| Autenticação | HTTP |
| Game server | recebido na resposta do login-server |
| Porta local esperada do Odin | `7172` |

O Thor envia as credenciais ao login-server, recebe uma sessão opaca e então se
conecta ao mundo anunciado pelo Odin. O fluxo legado direto por usuário e senha
na porta `7171` não é a entrada do perfil Hakai.

## Módulos Hakai

| Módulo | Responsabilidade |
|---|---|
| `game_pokemon_roster` | time Pokémon e estado visual do roster |
| `game_hakai_pokemon_domain` | modelo e contratos Pokémon no cliente |
| `game_hakai_combat_fx` | efeitos visuais de combate |
| `game_hakai_nurse_joy` | interface e feedback de cura |
| `game_hakai_travel` | ações de viagem |
| `game_hakai_coordinates` | suporte de coordenadas do ambiente |

O cliente também mantém as adaptações de login, protocolo, bestiário, store,
game interface e assets necessárias ao runtime atual.

## Pré-requisitos

- compilador com suporte a C++20;
- CMake e Ninja;
- dependências descritas em `vcpkg.json`;
- Odin e login-server configurados para o teste integrado;
- assets compatíveis com o protocolo `15.25`.

No Windows, prefira Developer PowerShell ou Developer Command Prompt do Visual
Studio.

## Build

Windows Release:

```powershell
cmake --preset windows-release
cmake --build --preset windows-release --target otclient
```

Linux Release:

```bash
cmake --preset linux-release
cmake --build --preset linux-release --target otclient -j4
```

Guias adicionais estão em [`docs/building/`](docs/building/).

## Assets 15.25

O Loki não versiona os pacotes modernos baixados do cliente. Instale-os
localmente nos caminhos usados pelo runtime:

```text
data/things/1525/
data/sounds/1525/
```

O auto-instalador permanece desativado por padrão em `init.lua`. As proteções
de integridade continuam estritas:

```lua
strictManifestSha256 = true
allowRawFallbackHashMismatch = false
```

Não mova os assets para uma raiz alternativa permanente e não relaxe a
verificação de hash para contornar um pacote inválido. Consulte
[`docs/client-assets-auto-install.md`](docs/client-assets-auto-install.md) para
o contrato completo.

## Executar localmente

Antes de abrir o Thor:

1. configure e inicie o banco usado pelo Odin;
2. inicie o Odin na porta `7172`;
3. inicie o login-server em `127.0.0.1:8088`;
4. confirme que os assets `15.25` estão instalados;
5. abra o executável gerado do Thor.

O título e o compact name do aplicativo são configurados como
`Hakai Engine Client Thor` e `hakai-engine-client-thor`.

## Testes Lua

Execute a partir da raiz `client/`:

```powershell
luajit tests/lua/test_hakai_login_configuration.lua
luajit tests/lua/test_extended_json_protocol.lua
luajit tests/lua/test_pokemon_domain.lua
```

Esses testes cobrem o endpoint local, o contrato JSON estendido e o domínio
Pokémon client-side.

## Estrutura principal

```text
client/
├── src/                         # núcleo C++
├── modules/                     # módulos oficiais e Hakai
├── mods/                        # módulos carregados pelo mod loader
├── data/                        # imagens, estilos, fontes e configuração
├── tests/lua/                   # contratos Lua do Thor
├── docs/                        # build e assets
├── init.lua                     # serviços e endpoint local
└── CMakePresets.json            # presets de build
```

## Plataformas

A fundação principal do Loki é desktop. O código herdado contém suporte para
Windows, Linux, macOS, Android e browser, mas a presença desses diretórios não
significa que todas as plataformas estejam validadas no estado alfa atual.

## Upstream e licença

Thor deriva do OTClient Redemption, que por sua vez reúne contribuições da
comunidade OTClient. Os avisos e créditos upstream permanecem no código e no
histórico do componente.

O cliente é distribuído conforme [`LICENSE`](LICENSE), licença MIT.

Recursos upstream:

- [OTClient Redemption](https://github.com/opentibiabr/otclient)
- [Wiki do OTClient](https://github.com/mehah/otclient/wiki)
