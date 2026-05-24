---
name: maintain-planner
description: Gerencia o ciclo de vida de planos no workspace C:\codes - cria pasta numerada NNNNNN-titulo-kebab, mantem indice por usuario (jz, jf) em C:\codes\plan\indice-planos-{usuario}.json com apenas planos em-andamento, e move para concluido/ ao fim. Use quando criar, iniciar, concluir ou listar planos; revisar estrutura de plan/; ou atribuir o proximo numero de plano. A skill e a dona da numeracao global e do indice.
---

# Manter Planejador

## Objetivo

Manter o ciclo de vida de planos verificaveis no workspace `C:\codes`. A skill e dona da numeracao global de planos, da estrutura de pasta `NNNNNN-titulo-kebab/` em qualquer `plan/` e do indice por usuario em `C:\codes\plan\indice-planos-{usuario}.json`.

## Conceitos

- **Numero de plano**: inteiro sequencial global no workspace, formatado com 6 digitos (`000001`, `000002`, ...). Unico entre todos os `plan/`.
- **Pasta de plano**: `NNNNNN-titulo-kebab/` dentro do `plan/` do contexto dono.
- **Indice por usuario**: `C:\codes\plan\indice-planos-{usuario}.{json,md}` lista apenas planos `em-andamento`. Quando o plano fica `concluido` ou `descartado`, sai do indice.
- **Concluido**: plano arquivado em `{plan_dir}/concluido/NNNNNN-titulo-kebab/`.

## Estrutura padrao

```
{contexto}/plan/
  NNNNNN-titulo-kebab/             <- plano em-andamento
    plano.md
    atividades.md (opcional)
    materiais/ (opcional)
  concluido/
    NNNNNN-titulo-kebab/
      plano.md ...
```

Contexto pode ser root (`C:\codes\plan`), empresa (`C:\codes\{empresa}\plan`), projeto (`C:\codes\{empresa}\{projeto}\plan`), skill (`C:\codes\skills\plan`), tool (`C:\codes\tools\{tool}\plan`).

## Indice por usuario (`indice-planos-{usuario}.json`)

```json
{
  "generated_at": "2026-05-24T12:00:00-03:00",
  "workspace_root": "C:/codes",
  "usuario": "jz",
  "em_andamento_total": 1,
  "proximo_numero": 39,
  "planos": [
    {
      "numero": "000001",
      "titulo": "controle de planos",
      "caminho": "C:/codes/plan/000001-controle-de-planos",
      "dono": "root",
      "empresa": null,
      "projeto": null,
      "skill": "maintain-planner",
      "prioridade": 1,
      "status": "em-andamento",
      "criado_em": "2026-05-24",
      "atualizado_em": "2026-05-24",
      "chamado": "SKILLS-JZ-CH-2026-00008",
      "skills_relacionadas": ["maintain-planner", "route-skills-by-context"]
    }
  ]
}
```

Regras:

1. `proximo_numero` e sempre `max(numero) + 1` considerando **todos os planos do workspace** (em-andamento + concluidos + descartados).
2. `planos[]` lista **apenas** os com `status: em-andamento`.
3. Indice e regenerado por `scripts/atualizar-indice-planos.ps1` apos qualquer criar/iniciar/concluir.

## Status de plano

| Status | Onde fica | No indice? |
|---|---|---|
| `em-andamento` | `{plan_dir}/NNNNNN-.../` | sim |
| `concluido` | `{plan_dir}/concluido/NNNNNN-.../` | nao |
| `descartado` | `{plan_dir}/descartado/NNNNNN-.../` | nao |

## Uso

1. **Criar plano novo**: `scripts/criar-plano.ps1 -Titulo "meu plano" -Dono root|<empresa>|<empresa>/<projeto>|skill|tools/<tool>`. Pega o proximo numero, cria pasta, gera `plano.md` template, regenera indice do usuario corrente.
2. **Iniciar plano existente** (mudar status -> em-andamento): `scripts/iniciar-plano.ps1 -Numero NNNNNN`.
3. **Concluir plano**: `scripts/concluir-plano.ps1 -Numero NNNNNN`. Move para `concluido/NNNNNN-.../` e regenera indice.
4. **Regenerar indice manualmente**: `scripts/atualizar-indice-planos.ps1 [-Usuario jz|jf]`.

## Limites

1. Nao criar plano fora do `plan/` do contexto dono.
2. Nao reutilizar numero (mesmo apos descartar).
3. Nao criar plano em-andamento sem chamado ativo vinculado (`chamado` no frontmatter).
4. Nao manter no indice planos concluidos/descartados.
5. Nao mover plano de uma pasta `plan/` para outra (numero acompanha contexto dono).
6. Nao criar regras de planejamento fora desta skill; tools sao apoio.
7. Nao concluir plano com atividades pendentes sem registrar excecao na sessao.

## Fluxo

1. Ler `C:\codes\AGENTS.md` e `C:\codes\tools\planejador\AGENTS.md`.
2. Confirmar chamado ativo.
3. Executar `route-skills-by-context` e registrar na sessao ativa.
4. Decidir contexto dono do plano (root, empresa, projeto, skill, tool).
5. Para criar: chamar `criar-plano.ps1`; para concluir: `concluir-plano.ps1`.
6. Validar plano com `scripts/validar-plano.ps1`.
7. Indice e regenerado automaticamente; conferir `em_andamento_total` e `proximo_numero`.
8. Toda atividade executavel deve registrar: skills candidatas, skill executora, skills de apoio, motivo.

## Scripts

1. `scripts/validar-plano.ps1`: valida estrutura minima de um `plano.md`.
2. `scripts/criar-plano.ps1 -Titulo <titulo> -Dono <root|empresa|empresa/projeto|skill|tools/tool> [-Prioridade N] [-Chamado <id>]`: aloca proximo numero, cria pasta, gera template `plano.md`, regenera indice.
3. `scripts/iniciar-plano.ps1 -Numero <NNNNNN>`: muda status do plano para em-andamento e regenera indice.
4. `scripts/concluir-plano.ps1 -Numero <NNNNNN>`: move pasta para `concluido/` e regenera indice.
5. `scripts/atualizar-indice-planos.ps1 [-Usuario <jz|jf>]`: varre todo o workspace, monta indice JSON+MD, salva em `C:\codes\plan\indice-planos-<usuario>.{json,md}`.

## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa skill executora, skills de apoio, motivo da escolha e validacao.
3. Sem esse registro, manter atividade como `bloqueado`.
