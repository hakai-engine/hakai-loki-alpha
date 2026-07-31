# Hakai Loki Alpha

[![Validate Loki tree](https://github.com/hakai-engine/hakai-loki-alpha/actions/workflows/validate-tree.yml/badge.svg)](https://github.com/hakai-engine/hakai-loki-alpha/actions/workflows/validate-tree.yml)

Loki é o monorepo alfa do Hakai Engine. Ele mantém na mesma revisão o servidor
Odin e o cliente Thor, formando a base integrada do PokéTibia do projeto.

> O projeto está em desenvolvimento ativo. A árvore atual é indicada para
> desenvolvimento e testes, não para um servidor público de produção.

## Componentes

| Caminho | Projeto | Responsabilidade | Base |
|---|---|---|---|
| [`server/`](server/) | Odin | Mundo, regras, persistência e autoridade do jogo | [OpenTibiaBR Canary](https://github.com/opentibiabr/canary) |
| [`client/`](client/) | Thor | Renderização, interface, input e comunicação com o servidor | [OTClient Redemption](https://github.com/opentibiabr/otclient) |

## Fluxo local

```text
Thor
  │
  ├── HTTP 15.25 ──> login-server (127.0.0.1:8088/login)
  │                         │
  │                         └── sessão + mundo disponível
  │
  └── game protocol ──> Odin (127.0.0.1:7172)
```

O Thor usa autenticação HTTP e recebe do login-server a sessão e o endereço do
mundo. O gameplay acontece diretamente no Odin pela porta `7172`. O perfil
local padrão usa protocolo `15.25` e `authType = "session"`.

## Sistemas presentes

Odin reúne a fundação server-side para:

- catálogo das 151 espécies de Kanto;
- nature, gênero, IVs, atributos e progressão;
- golpes, tipos, combate e efeitos;
- Team, summon, recall, faint e battle lock;
- corpse, captura, Capture Bag e Poké Balls;
- evolução, equipamentos, cura e Nurse Joy;
- viagem, surf, fly e políticas de alvo;
- protocolo de roster entre servidor e cliente.

Thor contém:

- login HTTP local para o protocolo `15.25`;
- roster visual do time Pokémon;
- domínio Pokémon client-side;
- feedback da Nurse Joy;
- efeitos de combate Hakai;
- módulos de viagem e coordenadas;
- identidade visual e interfaces em evolução.

Esses itens representam código presente na árvore alfa. Consulte testes,
issues e pull requests antes de assumir que um fluxo está pronto para produção.

## Começar

Clone o monorepo:

```bash
git clone https://github.com/hakai-engine/hakai-loki-alpha.git
cd hakai-loki-alpha
```

Prepare primeiro o Odin:

```powershell
cd server
Copy-Item config.lua.dist config.lua
cmake --preset windows-release
cmake --build --preset windows-release --target canary
```

Configure o banco em `server/config.lua` e inicie o login-server local seguindo
o [README do Odin](server/README.md).

Depois compile o Thor:

```powershell
cd ..\client
cmake --preset windows-release
cmake --build --preset windows-release --target otclient
```

Os pacotes modernos do cliente não são versionados no Loki. Instale os assets
`15.25` localmente nos caminhos documentados no
[README do Thor](client/README.md).

## Estrutura

```text
hakai-loki-alpha/
├── server/       # Odin
├── client/       # Thor
├── manifests/    # proveniência da importação
├── tools/        # validação e manutenção do monorepo
└── .github/      # CI pertencente ao Loki
```

## Validação

Valide a árvore antes de publicar:

```powershell
pwsh -File tools/Validate-LokiTree.ps1
```

O gate bloqueia, entre outros:

- chaves privadas, credenciais e configuração local;
- builds, logs, bancos, caches e backups;
- pacotes locais `data/things/1525` e `data/sounds/1525`;
- repositórios e automações GitHub aninhados;
- o módulo proprietário herdado `game_wheel`;
- arquivos individuais com 95 MiB ou mais.

A origem do snapshot inicial está registrada em
[`manifests/import-snapshot.json`](manifests/import-snapshot.json).

## Documentação dos componentes

- [Odin — servidor](server/README.md)
- [Thor — cliente](client/README.md)
- [Build e desenvolvimento do Canary](server/docs/development.md)
- [Assets modernos do Thor](client/docs/client-assets-auto-install.md)

## Licenças e marcas

Odin e Thor preservam os arquivos de licença e os avisos recebidos de seus
respectivos upstreams. Não existe uma licença única aplicada à raiz inteira.

Hakai Engine é um projeto de fãs independente. Este repositório não é afiliado
à Nintendo, Creatures Inc., GAME FREAK, The Pokémon Company ou CipSoft e não
concede direitos sobre suas marcas ou assets.
