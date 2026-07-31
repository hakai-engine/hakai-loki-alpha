# Hakai Loki Alpha

Monorepo alfa do Hakai Engine, reunindo os dois componentes que formam o
runtime atual:

| Caminho | Projeto | Base |
|---|---|---|
| [`server/`](server/) | Odin, servidor autoritativo | OpenTibiaBR Canary |
| [`client/`](client/) | Thor, cliente desktop | OTClient Redemption |

O Loki mantém servidor e cliente na mesma revisão para facilitar a evolução dos
contratos de rede, sistemas Pokémon, assets, testes e releases do projeto.

## Começar

```bash
git clone https://github.com/hakai-engine/hakai-loki-alpha.git
cd hakai-loki-alpha
```

Consulte as instruções específicas em
[`server/README.md`](server/README.md) e
[`client/README.md`](client/README.md).

## Conteúdo da importação

Esta árvore é um snapshot controlado dos worktrees locais Odin e Thor em
31 de julho de 2026. A origem e as contagens da importação estão registradas em
[`manifests/import-snapshot.json`](manifests/import-snapshot.json).

Não fazem parte do repositório:

- builds, executáveis, logs, bancos e configurações locais;
- backups e caches de geração;
- chaves privadas e credenciais;
- pacotes de assets baixados para `data/things/1525` e `data/sounds/1525`;
- o módulo proprietário herdado `game_wheel`;
- repositórios Git e automações GitHub aninhados.

Antes de publicar uma nova importação, execute:

```powershell
pwsh -File tools/Validate-LokiTree.ps1
```

## Licenças e marcas

Odin e Thor preservam seus próprios arquivos de licença e os avisos dos
projetos upstream. Não existe uma licença única para toda a raiz. Este
repositório não concede direitos sobre marcas Pokémon, Tibia ou assets de
terceiros.
