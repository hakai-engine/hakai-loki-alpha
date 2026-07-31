# Contrato de UI — Hakai Engine Thor

Versão: 1.0  
Status: obrigatório para toda criação ou alteração visual  
Cliente-alvo: `hakai-engine-client-thor`

## 1. Objetivo

Este contrato separa três entregas que não podem mais ser confundidas:

1. **Modelo visual:** imagem para decidir composição, identidade e acabamento.
2. **Pacote de produção:** artes recortadas, transparentes, dimensionadas e com todos os estados.
3. **Integração OTClient:** widgets reais, OTUI/Lua preservados e validação dentro do cliente.

Um modelo bonito não é automaticamente um asset pronto. Uma imagem recortada não é automaticamente um widget. Nenhuma arte será aplicada ao cliente antes da aprovação explícita do modelo.

## 2. Fonte de verdade

Em caso de conflito, vale esta ordem:

1. pedido atual e aprovação explícita do usuário;
2. especificação aprovada do componente;
3. manifesto do pacote de produção;
4. contrato técnico existente do módulo OTClient;
5. liberdade estética apenas no que não estiver especificado.

Frases como **“aprovado”**, **“pode produzir”** ou **“aplica essa”** mudam o estado da entrega. Comentários como “ficou bonito” não autorizam aplicação automaticamente.

## 3. Estados obrigatórios

| Estado | Significado | Pode alterar o cliente? |
|---|---|---:|
| `DRAFT` | conceito em avaliação | não |
| `VISUAL_APPROVED` | composição congelada pelo usuário | não |
| `PRODUCTION_READY` | assets e especificação técnica validados | ainda não |
| `INTEGRATED` | aplicado em cópia de trabalho/cliente autorizado | sim |
| `LIVE_APPROVED` | conferido ao vivo e aceito | concluído |

Cada mudança visual relevante cria uma nova versão. Depois de `VISUAL_APPROVED`, nenhuma simplificação, troca de cor, remoção de ornamento, mudança de proporção ou reposicionamento é permitida sem nova aprovação.

## 4. Fluxo de trabalho obrigatório

### Etapa A — Descoberta técnica

Antes de desenhar:

- localizar módulo, `.otui`, `.lua`, estilos herdados e imagens atuais;
- registrar a hierarquia de widgets e os IDs usados pelo Lua;
- medir dimensões nativas, `image-border`, padding, grid, espaçamentos e estados;
- identificar quais partes são estáticas e quais são dados/widgets reais;
- capturar o estado atual do cliente quando necessário.

Saída: mapa técnico curto anexado à especificação do componente.

### Etapa B — Modelo visual

O modelo deve ser mostrado com:

- nome e versão;
- resolução do modelo;
- indicação visível de **MODELO — NÃO APLICADO**;
- lista do que será imagem estática;
- lista do que continuará widget real;
- limitações técnicas conhecidas;
- comparação com a referência aprovada, quando houver.

O modelo não será aplicado nem recortado como “final” até o usuário aprová-lo.

### Etapa C — Congelamento visual

Após aprovação, registrar:

- imagem exata aprovada e seu caminho;
- dimensões e proporções;
- paleta;
- ornamentos e personagens;
- tipografia visual pretendida;
- alinhamentos;
- estados interativos;
- itens proibidos de remover ou simplificar.

Essa ficha passa a ser a referência visual vinculante.

### Etapa D — Produção de assets

Produzir cada elemento em tamanho nativo ou em escala inteira planejada. O pacote deve conter:

- moldura limpa, sem textos ou dados dinâmicos;
- fundo interno, se separado;
- cantos, laterais e ornamentos completos;
- botões `normal`, `hover`, `pressed` e `disabled`;
- estados `on/selected` quando aplicáveis;
- slots `normal`, `hover`, `pressed`, `selected` e `disabled`;
- trilha e polegar da scrollbar com estados necessários;
- ícones recortados individualmente;
- `contact-sheet.png` para conferência;
- `manifest.json` ou tabela equivalente;
- especificação de `image-border`/9-slice e dimensões.

Todo PNG destinado a recorte precisa ter canal alpha real. Fundo preto, verde, xadrez ou cor sólida simulando transparência reprova o asset.

### Etapa E — Revisão pré-integração

Antes de tocar no cliente, mostrar:

- a janela vazia;
- a janela montada com widgets de demonstração;
- a folha de estados;
- uma visualização em tamanho real, sem suavização;
- a lista de arquivos que serão alterados;
- os IDs e callbacks que serão preservados.

Somente depois de **“pode aplicar”** começa a integração.

### Etapa F — Integração

- criar backup datado de todo arquivo substituído;
- trabalhar apenas no cliente autorizado;
- copiar assets sem sobrescrever arquivos não relacionados;
- manter texto, valores, itens, paginação e controles como widgets reais;
- preservar IDs exigidos pelo Lua;
- usar anchors e medidas inteiras;
- usar `image-border`/9-slice ou peças modulares para molduras redimensionáveis;
- usar `image-smooth: false` em pixel art, salvo exceção aprovada;
- não alterar lógica Lua fora do escopo aprovado;
- não mudar estilo global para corrigir um único módulo.

### Etapa G — Validação ao vivo

Reiniciar o cliente e testar:

- visual em 100% de escala;
- tamanhos mínimo, padrão e máximo da janela;
- capacidades diferentes de container;
- normal, hover, pressed, disabled e selected;
- abrir, fechar, minimizar, mover e redimensionar;
- scrollbar, paginação, botão de subir, menu e trava;
- item vazio, item preenchido, stack, tier, duração e cargas;
- resoluções 1920×1080 e ultrawide quando aplicável;
- logs sem novos erros de fonte, asset, anchor, estilo ou callback.

A prova final inclui captura direta da janela pelo título/processo e um resumo dos testes.

## 5. Regras invioláveis de fidelidade

1. Não redesenhar silenciosamente uma arte aprovada.
2. Não simplificar ornamentos por conveniência técnica.
3. Não esticar uma moldura inteira; proteger cantos com 9-slice ou peças separadas.
4. Não embutir título, saldo, números, itens, lista, scrollbar ou botões funcionais na textura de fundo.
5. Não apresentar crop de mockup como asset final.
6. Não reduzir diretamente uma arte grande para 32/34 px e chamar de pixel art final. O asset pequeno deve ser redesenhado/limpo no tamanho nativo.
7. Não usar dimensão aproximada. Toda peça de produção tem largura e altura declaradas.
8. Não inventar nome de fonte. A fonte precisa estar registrada e carregada no cliente.
9. Não apagar alpha nem deixar halos pretos nas bordas.
10. Não aplicar no cliente sem aprovação explícita.
11. Não declarar “pronto” antes do teste ao vivo.
12. Se o motor impedir fidelidade exata, mostrar o limite antes de produzir e propor alternativas para aprovação.

## 6. Contrato técnico do container Thor

O container atual é criado por `modules/game_containers/containers.lua` a partir de `ContainerWindow` em `modules/game_containers/container.otui`.

### IDs e relações que devem ser preservados

- `contentsPanel`: painel real que recebe os itens.
- `containerItemWidget`: item representativo usado pelo módulo.
- `miniwindowScrollBar`: scrollbar ligada ao conteúdo.
- `upButton`: navegação para o container anterior.
- `pagePanel`: paginação.
- `contextMenuButton`: menu contextual.
- `lockButton`: trava.
- `minimizeButton`: minimizar/restaurar.
- `miniwindowTitle`: título preenchido pelo Lua.
- `bottomResizeBorder`: redimensionamento vertical.
- `separator`: separação do conteúdo e paginação.

Também permanecem válidos os IDs herdados de `MiniWindow`, inclusive `miniwindowHeader`, `miniwindowTopBar` e `closeButton`.

### Comportamento que não pode virar imagem

- O Lua cria widgets `Item` em tempo de execução.
- O layout do `contentsPanel` é grid.
- O tamanho-base atual do item é `34×34`.
- O espaçamento-base atual do grid é `3 px`.
- O título vem de `container:getName()`.
- Paginação e scrollbar são exibidas/reancoradas em tempo de execução.
- Tier, duração, cargas, quantidade e conteúdo do slot são dados reais.

### Como aplicar a arte

- Moldura: textura 9-slice ou conjunto modular de cantos/laterais.
- Ornamentos que ultrapassam a caixa: widgets filhos `phantom: true`, separados da área clicável.
- Título: `Label` real centralizado, nunca pintado na moldura final.
- Botões: `UIButton` real com imagens de estado.
- Slots: `UIItem`/`Item` real com fundo temático.
- Scrollbar: controle real com skin Hakai.
- Áreas de clique devem considerar a peça inteira, sem cortar bordas decorativas.

## 7. Manifesto mínimo de produção

Cada asset deve registrar:

| Campo | Exemplo |
|---|---|
| `file` | `container_frame.png` |
| `role` | moldura 9-slice |
| `width` / `height` | `192` / `150` |
| `alpha` | `true` |
| `targetWidget` | `ContainerWindow` |
| `state` | `normal` |
| `imageBorder` | `24,24,24,24` |
| `smooth` | `false` |
| `sourceModel` | `container-gen1-psychic-v1` |
| `approvedVersion` | `1.0` |

O manifesto deve incluir todas as peças. Arquivo ausente ou estado ausente impede `PRODUCTION_READY`.

## 8. Critérios de aceite

### Aceite visual

- composição corresponde à imagem aprovada;
- proporções e cores foram preservadas;
- nenhum elemento obrigatório foi removido;
- o resultado é exibido no tamanho real.

### Aceite técnico

- PNGs têm alpha correto;
- bordas não quebram ao redimensionar;
- widgets reais continuam funcionais;
- IDs e callbacks permanecem válidos;
- não há sobreposição, clipping ou desalinhamento;
- não surgem erros no log;
- existe backup e lista exata das alterações.

### Aceite final

O trabalho só recebe `LIVE_APPROVED` depois de o usuário ver a captura real do cliente e aprovar.

## 9. Formato obrigatório das entregas

### Ao mostrar um modelo

> Modelo `nome-versão` — não aplicado.  
> Estático: ...  
> Widgets reais: ...  
> Limites/decisões: ...  
> Aguardando aprovação visual.

### Antes de aplicar

> Pacote `nome-versão` pronto para revisão.  
> Assets: ...  
> Arquivos que serão alterados: ...  
> IDs preservados: ...  
> Aguardando autorização para integração.

### Depois de aplicar

> Integrado no cliente autorizado.  
> Backup: ...  
> Captura real: ...  
> Testes: ...  
> Erros novos: nenhum / lista.  
> Aguardando aceite final.

## 10. Regra de parada

Qualquer divergência entre modelo, pacote e cliente interrompe a produção. Corrige-se a causa; não se mascara com recortes, escalas, fundos sólidos ou simplificação visual.
