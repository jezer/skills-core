---
name: maintain-activities
description: Criar, atualizar, marcar ou verificar atividades dentro de planos em C:\codes. Use quando Codex precisar quebrar trabalho em atividades, atualizar status, registrar data de implementacao, validar criterio de aceite, ou impedir execucao de atividade sem escopo, criterio ou skill recomendada.
---

# Manter Atividades

## Objetivo

Manter atividades verificaveis dentro de planos.

## Uso

1. Usar quando o usuario pedir criacao, revisao ou atualizacao de atividades.
2. Usar para marcar atividade como `pendente`, `em andamento`, `bloqueado`, `feito` ou `cancelado`.
3. Usar para validar se uma atividade pode ser executada.

## Limites

1. Nao marcar atividade como `feito` sem evidencia objetiva.
2. Nao executar atividade sem escopo, criterio de aceite e skill recomendada.
3. Nao criar regras de planejamento; isso pertence a `C:\codes\tools\planejador`.
4. Nao transformar pedido para outro contexto em execucao direta; registrar ou verificar atividade no `plan` do contexto dono.
5. Nao permitir atividade persistente sem chamado ativo quando o workspace exigir rastreabilidade.
6. Nao permitir atividade executavel sem explicitar skills eleitas por condicao da atividade.
7. Nao duplicar regra de arquivamento de concluido em outras skills; esta regra pertence somente a `maintain-activities`.
8. Nao permitir inicio de atividade persistente sem evidenciar execucao de `route-skills-by-context` na sessao ativa.

## Fluxo

1. Ler `C:\codes\tools\planejador\AGENTS.md`.
2. Abrir o plano indicado.
3. Localizar a atividade por identificador, inclusive quando o plano usar prefixos especificos como `AT-000` ou `SK-CTX-000`.
4. Eleger skills recomendadas usando indices auxiliares em `C:\codes\skills\indices` antes de gravar a atividade.
5. Verificar dependencias, escopo, skills e criterio de aceite.
6. Atualizar status e data somente quando houver evidencia ou pedido explicito.
7. Preservar o formato padrao da atividade.
8. Conferir se atividades que afetem outro contexto apontam para o `plan` do contexto dono.
9. Conferir se a skill recomendada tem proposito aderente a atividade.
10. Quando houver risco de ambiguidade, usar `route-skills-by-context` para eleger skills basicas, de empresa, de projeto e globais de apoio.
11. Quando todas as atividades do plano estiverem `feito` ou `cancelado`, mover o plano para `concluido/` no mesmo diretorio.
12. Antes de iniciar, executar ou concluir atividade persistente, validar na sessao ativa os campos de roteamento de skills.
13. Aplicar `scripts/validar-roteamento-obrigatorio.ps1` como gate tecnico antes de liberar atividade persistente.

## Scripts

1. `scripts/atualizar-atividade.ps1`: atualiza status, data e observacao de uma atividade Markdown pelo identificador da atividade.
2. `scripts/recomendar-skills-atividade.ps1`: recomenda skills por atividade usando `skills-index.json`, `contexto-map.json` e `aliases.json`.
3. Integrar com `C:\codes\skills\core\router\route-skills-by-context\scripts\selecionar-skills.ps1` quando a atividade exigir descoberta de skills.
4. `scripts/arquivar-plano-concluido.ps1`: move plano para `concluido/` quando todos os status estao concluidos.
5. `C:\codes\skills\core\skill_registry\maintain-skills\scripts\validar-roteamento-sessao.ps1`: gate de validacao dos campos obrigatorios de roteamento na sessao do chamado.
6. `scripts/validar-roteamento-obrigatorio.ps1`: valida se a sessao ativa contem `route-skills-by-context` nos campos de roteamento obrigatorios.


## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa:
- skill executora
- skills de apoio
- motivo da escolha
- validacao da escolha
3. Sem esse registro, manter atividade como `bloqueado`.

