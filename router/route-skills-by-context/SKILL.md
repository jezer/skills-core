---
name: route-skills-by-context
description: Eleger skills executoras por contexto e tipo de atividade no workspace C:\codes. Use quando for necessario decidir, antes da execucao, quais skills basicas, de empresa, de projeto e globais de apoio devem ser acionadas, mantendo coerencia com root, ferramentas globais e compatibilidade Gemini/Codex.
metadata:
  camada: padroes
  escopo_negativo:
    - nao implementa mudancas persistentes por conta propria
    - nao substitui as skills donas da execucao
  saidas:
    - selecionar-skills.ps1
    - registro de roteamento na sessao
  triggers:
    - rotear skills
    - escolher skill executora
    - roteamento obrigatorio
---

# Rotear Skills por Contexto

## Objetivo

Definir uma lista objetiva de skills executoras para uma atividade, com base em contexto dono e condicao da atividade.

## Uso

1. Usar obrigatoriamente no inicio da sessao ativa de qualquer atividade persistente.
2. Reexecutar antes de cada novo bloco de mudanca persistente durante a mesma sessao.
3. Usar antes de execucoes multi-contexto ou com risco de conflito entre regras.
4. Usar quando for necessario eleger skills por camada:
   - basico/global;
   - empresa;
   - projeto;
   - apoio global.
5. Usar para gerar rastreabilidade de "condicao -> skills eleitas".
6. Quando o contexto indicar nova empresa, novo projeto ou atualizacao de inventario, incluir `sync-repositories-index` como skill de apoio.
7. Quando a atividade envolver plano, eleger obrigatoriamente `maintain-planner` antes de qualquer escrita de plano.
8. Em qualquer atividade persistente, manter `maintain-planner` entre as skills de apoio para gate de governanca.

## Limites

1. Nao implementa mudancas persistentes por conta propria.
2. Nao substitui skills donas da execucao.
3. Nao ignora hierarquia de contexto (`projeto > empresa > root`).
4. Nao permitir criacao manual de plano sem roteamento que inclua `maintain-planner`.
5. Fora do proposito desta skill, devolver ao `route-skills-by-context` (nao improvisar).

## Fluxo

1. Executar o CHECK DE FRESCOR das skills (plano skills 000133, caso 3-A): `scripts\verificar-frescor-skills.ps1` consulta `GET /skills/sync/status` na API do all_IA (timeout ~500ms); se houver skill alterada depois da ultima sincronizacao banco -> `dist/`, o sincronizador e invocado automaticamente antes de rotear. Backend fora = fallback offline: usa o `dist/` local como esta e registra pendencia em `skills/indices/.sync-pendente`.
2. Ler `C:\codes\AGENTS.md`.
3. Ler regras do contexto mais especifico envolvido.
4. Identificar tipo da atividade (`planejamento`, `execucao-tecnica`, `estrutura-contexto`, `git-publicacao`, `chamados-rastreabilidade`).
5. Eleger skills com `scripts\selecionar-skills.ps1` (o indice oficial de skills e o BANCO: `GET /skills/index`).
6. Registrar no plano/atividade a lista final de skills executoras.
7. Registrar na sessao ativa: skills candidatas, skill executora, skills de apoio e motivo da escolha.
8. Antes de encerrar a atividade persistente, validar o registro com `C:\codes\skills\core\planner\maintain-activities\scripts\validar-roteamento-obrigatorio.ps1`.

## Roteamento e fallback (plano 000125)

1. Este roteador e o UNICO orquestrador: quando uma skill recebe demanda
   fora do seu proposito, ela NAO improvisa - declara "isto nao e meu
   proposito" e devolve a demanda para ca.
2. Criterio objetivo de devolucao: o `metadata.escopo_negativo` do manifesto
   da skill (formato oficial na `maintain-skills`).
3. Ao receber a devolucao, re-rotear considerando a CAMADA declarada
   (`metadata.camada`): pedido especifico que caiu numa skill de FERRAMENTA
   vai para a skill de ATIVIDADE da cadeia (ou orienta criar uma); skill de
   atividade consulta a de ferramenta declarada em `metadata.dependencias`;
   skill de PADROES compoe as duas.
4. Se nenhuma skill cobre o proposito, registrar a lacuna e orientar a
   criacao de skill focada via `maintain-skills` - nunca deixar uma skill
   resolver fora do escopo.

## Scripts

1. `scripts/selecionar-skills.ps1`: retorna skills sugeridas por contexto e tipo de atividade.
2. `scripts/verificar-frescor-skills.ps1`: check de frescor no inicio do prompt (000133) - dispara a sync banco -> dist/ quando defasado; offline registra pendencia e segue com o dist/ local.


## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa:
- skill executora
- skills de apoio
- motivo da escolha
- validacao da escolha
3. Sem esse registro, manter atividade como `bloqueado`.

