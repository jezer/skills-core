---
name: route-skills-by-context
description: Eleger skills executoras por contexto e tipo de atividade no workspace C:\codes. Use quando for necessario decidir, antes da execucao, quais skills basicas, de empresa, de projeto e globais de apoio devem ser acionadas, mantendo coerencia com root, ferramentas globais e compatibilidade Gemini/Codex.
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

## Fluxo

1. Ler `C:\codes\AGENTS.md`.
2. Ler regras do contexto mais especifico envolvido.
3. Identificar tipo da atividade (`planejamento`, `execucao-tecnica`, `estrutura-contexto`, `git-publicacao`, `chamados-rastreabilidade`).
4. Eleger skills com `scripts\selecionar-skills.ps1`.
5. Registrar no plano/atividade a lista final de skills executoras.
6. Registrar na sessao ativa: skills candidatas, skill executora, skills de apoio e motivo da escolha.
7. Antes de encerrar a atividade persistente, validar o registro com `C:\codes\skills\core\planner\maintain-activities\scripts\validar-roteamento-obrigatorio.ps1`.

## Scripts

1. `scripts/selecionar-skills.ps1`: retorna skills sugeridas por contexto e tipo de atividade.


## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa:
- skill executora
- skills de apoio
- motivo da escolha
- validacao da escolha
3. Sem esse registro, manter atividade como `bloqueado`.

