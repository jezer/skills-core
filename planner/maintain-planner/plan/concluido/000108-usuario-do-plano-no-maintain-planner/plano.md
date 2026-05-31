# 000108 - usuario do plano no maintain planner

- Numero: 000108
- Titulo: usuario do plano no maintain planner
- Dono: skills/core/planner/maintain-planner
- Usuario atual: jz
- Prioridade: 1
- Status: concluido
- Criado em: 2026-05-31
- Atualizado em: 2026-05-31
- Chamado: SKILLS-JZ-CH-2026-00011
- Skills relacionadas: route-skills-by-context,maintain-planner,maintain-activities,maintain-skills

## Objetivo

Atualizar o `maintain-planner` para registrar o usuario atual do plano a partir de `C:\codes\personalizado.md`, garantindo que planos criados nesta maquina carreguem `- Usuario atual: jz` no cabecalho e exponham essa informacao no indice.

## Escopo

1. Incluir `Usuario atual` no template de `criar-plano.ps1`.
2. Expor `usuario_atual` em `indice-planos-{usuario}.json` e na tabela Markdown do indice.
3. Documentar a regra no `SKILL.md` do `maintain-planner`.
4. Regularizar os planos `000101` a `000107` com `Usuario atual: jz`.
5. Garantir que os planos `000101` a `000107` usem o mesmo chamado do plano `000034`: `TOOLS-JZ-CH-2026-00009`.

## Atividades planejadas

| # | Atividade | Status | Skill executora | Saida |
|---|---|---|---|---|
| A1 | Atualizar template de criacao de plano com `Usuario atual` | feito | maintain-planner | `criar-plano.ps1` atualizado |
| A2 | Atualizar indice de planos com `usuario_atual` | feito | maintain-planner | `atualizar-indice-planos.ps1` atualizado |
| A3 | Documentar regra no `maintain-planner` | feito | maintain-planner | `SKILL.md` atualizado |
| A4 | Regularizar planos `000101` a `000107` | feito | maintain-planner | Cabecalhos com usuario e chamado |
| A5 | Regenerar indice e validar | feito | maintain-planner | Indices atualizados e validacoes executadas |

## Criterios de aceite

Criterio de aceite principal: todo plano novo passa a registrar o usuario atual da maquina e o indice permite filtrar/auditar planos por usuario.

1. `criar-plano.ps1` grava `- Usuario atual: <usuario>` no `plano.md`.
2. `atualizar-indice-planos.ps1` inclui `usuario_atual` em cada item do JSON.
3. `indice-planos-jz.md` mostra coluna de usuario.
4. Planos `000101` a `000107` possuem `Usuario atual: jz`.
5. Planos `000101` a `000107` possuem `Chamado: TOOLS-JZ-CH-2026-00009`.

## Checklist

- [x] Confirmar usuario em `C:\codes\personalizado.md`.
- [x] Atualizar scripts do `maintain-planner`.
- [x] Atualizar documentacao da skill.
- [x] Regularizar planos `000101` a `000107`.
- [x] Regenerar indice.
- [x] Validar plano e sessao.

## Evidencias de fechamento

1. `C:\codes\personalizado.md` contem `- Usuario atual: jz`.
2. `criar-plano.ps1` inclui `- Usuario atual: jz` em novos planos.
3. `atualizar-indice-planos.ps1` inclui `usuario_atual` no JSON e no Markdown do indice.
4. `indice-planos-jz.json` registra `usuario_atual: jz` para planos em andamento.
5. Planos `000101` a `000107` possuem `Usuario atual: jz` e `Chamado: TOOLS-JZ-CH-2026-00009`.
6. `quick_validate.py` validou `maintain-planner` com sucesso.
7. `validate-skills` geral gerou relatorio, com falha preexistente em `sci-content-flow` fora do escopo desta alteracao.

## Skills recomendadas atuais

- `maintain-planner`
- `maintain-activities`
- `route-skills-by-context`

## Riscos

- Planos antigos sem `Usuario atual` continuarem sem rastreabilidade por maquina ate serem regularizados.
- Divergencia entre usuario do plano e usuario do chamado quando houver migracao entre maquinas.