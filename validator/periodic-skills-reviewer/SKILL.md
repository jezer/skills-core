---
name: periodic-skills-reviewer
description: Executar revisoes periodicas de skills para detectar sobreposicao de proposito, falhas de dependencia e gaps de qualidade.
---

# Revisor Periodico Skills

## Objetivo

Auditar continuamente o ecossistema de skills e abrir correcoes quando necessario.

## Uso

1. Revisao semanal de sobreposicao.
2. Revisao mensal de performance e aderencia.

## Limites

1. Nao implementar mudancas diretas sem atividade aprovada.
2. Nao substituir skill dona de manutencao.

## Dependencias operacionais

1. `maintain-skills`
2. `maintain-activities`
3. `route-skills-by-context`


## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa:
- skill executora
- skills de apoio
- motivo da escolha
- validacao da escolha
3. Sem esse registro, manter atividade como `bloqueado`.
