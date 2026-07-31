# Container Gen 1 Psychic — Hakai UI

## Identificação

- Componente: janela de container/backpack
- Versão: 1.0
- Módulo: `game_containers`
- Estado atual: `VISUAL_APPROVED`
- Cliente-alvo: `hakai-engine-client-thor`

## Referência visual congelada

- Modelo aprovado: `output/imagegen/hakai-gen1-psychic-container-pokeball-ui-concept.png`
- Tema: Gen 1, confronto psíquico Mewtwo × Mew
- Moldura: azul-marinho quase preto, violeta, ciano e dourado
- Elemento superior central: Master Ball
- Lateral esquerda: identidade azul de Mewtwo
- Lateral direita: identidade rosa de Mew
- Cantos inferiores: elementos de Poké Ball
- Cristais decorativos: proibidos; foram substituídos por elementos Pokémon

Não é permitido remover ou simplificar silenciosamente esses elementos.

## Situação dos arquivos já extraídos

Diretório de referência:

`output/imagegen/hakai-gen1-container-pokeball-assets`

Os recortes existentes são **referências de extração**, não estão automaticamente aprovados como assets nativos do OTClient. Antes da integração, cada peça precisa:

- ter alpha real;
- preservar a borda completa;
- ser redesenhada/limpa no tamanho final;
- possuir estados interativos quando clicável;
- passar pelo teste de 9-slice e escala 1:1.

## Contrato técnico atual

- OTUI: `modules/game_containers/container.otui`
- Lua: `modules/game_containers/containers.lua`
- Estilo herdado: `MiniWindow`
- Item herdado: `Item < UIItem`
- Célula-base: `34×34`
- Espaçamento-base: `3 px`

### IDs obrigatórios

- `contentsPanel`
- `containerItemWidget`
- `miniwindowScrollBar`
- `upButton`
- `pagePanel`
- `contextMenuButton`
- `lockButton`
- `minimizeButton`
- `miniwindowTitle`
- `bottomResizeBorder`
- `separator`
- `closeButton`
- `miniwindowHeader`
- `miniwindowTopBar`

## Separação obrigatória

### Pode ser arte estática

- fundo interno;
- moldura e 9-slice;
- ornamentos laterais;
- emblemas não clicáveis;
- textura dos slots vazios;
- decoração da barra de título.

### Deve continuar widget real

- título;
- fechar, minimizar, subir, travar e menu;
- scrollbar;
- paginação;
- todos os slots;
- itens, quantidades, tiers, duração e cargas;
- tooltip e interação de mouse;
- resize border.

## Próximo gate

Para mudar de `VISUAL_APPROVED` para `PRODUCTION_READY`, ainda é obrigatório entregar:

- janela vazia limpa;
- moldura 9-slice em tamanho-alvo;
- slot nativo `34×34` e seus estados;
- botões e estados;
- skin da scrollbar;
- manifesto;
- contact sheet;
- montagem de teste em escala 1:1;
- revisão do usuário antes da aplicação.
