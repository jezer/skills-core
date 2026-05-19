---
name: maintain-planner
description: Criar, revisar ou validar planos antes de implementacoes persistentes no workspace C:\codes. Use quando Codex precisar organizar objetivo, escopo, fora de escopo, atividades, dependencias, riscos, skills recomendadas e criterios de aceite; ou quando uma implementacao ainda nao tiver plano claro conforme C:\codes\tools\planejador.
---

# Manter Planejador

## Objetivo

Criar e revisar planos verificaveis antes de implementacoes persistentes.

## Uso

1. Usar quando o usuario pedir plano, planejamento ou revisao de plano.
2. Usar antes de implementar mudancas persistentes sem plano claro.
3. Usar para validar se atividades possuem escopo, criterio de aceite e skills recomendadas.
4. Usar para registrar pedidos no `plan` do contexto dono quando uma necessidade afetar outro contexto.
5. Usar para interromper execucao persistente quando nao houver skill aderente, contexto dono claro ou criterio de aceite.
6. Usar para exigir roteamento explicito de skills por atividade antes da implementacao persistente.
7. Usar como skill obrigatoria para qualquer criacao, edicao ou validacao de arquivos de plano.

## Limites

1. Nao implementar atividades durante revisao de plano, salvo pedido explicito.
2. Nao duplicar regras completas de `root`, `skills` ou projetos.
3. Nao marcar atividade como feita sem evidencia verificavel.
4. Nao planejar alteracao direta em outro contexto sem indicar o `plan` do contexto dono.
5. Nao tratar tool global como existente antes de haver plano aprovado e pasta criada.
6. Nao atribuir a uma skill o proposito de outra skill ja existente.
7. Nao permitir plano criado fora da pasta `plan` do contexto dono (projeto, empresa ou root), salvo regra especifica mais restritiva no contexto.

## Fluxo

1. Ler `C:\codes\AGENTS.md`.
2. Ler `C:\codes\tools\planejador\AGENTS.md`.
3. Confirmar chamado ativo.
4. Executar `route-skills-by-context` como etapa obrigatoria e registrar skills candidatas, skill executora, skills de apoio e motivo da escolha na sessao ativa.
5. Verificar se existe plano aplicavel.
6. Definir o contexto dono do plano (projeto, empresa ou root) e garantir escrita em `plan/` desse contexto.
7. Criar ou revisar plano com objetivo, escopo, fora de escopo, atividades, dependencias, riscos e criterios de aceite.
8. Indicar skills recomendadas atuais e skills futuras relacionadas quando aplicavel.
9. Validar o plano antes de recomendar implementacao.
10. Se a atividade afetar outro contexto, criar pedido no `plan` do contexto dono e manter o contexto solicitante somente como origem da necessidade.
11. Quando o plano envolver tools, usar `C:\codes\tools` como contexto dono e deixar claro que tools sao artefatos de apoio, nao skills.
12. Toda atividade executavel deve registrar: skills candidatas, skill executora, skills de apoio e motivo da escolha.

## Scripts

1. `scripts/validar-plano.ps1`: valida estrutura minima de um plano Markdown.


## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa:
- skill executora
- skills de apoio
- motivo da escolha
- validacao da escolha
3. Sem esse registro, manter atividade como `bloqueado`.
