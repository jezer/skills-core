---
name: maintain-planner
description: Gerencia o ciclo de vida de planos no workspace C:\codes - cria pasta numerada NNNNNN-titulo-kebab, mantem indice por usuario (jz, jf) em C:\codes\plan\indice-planos-{usuario}.json com apenas planos em-andamento, e move para concluido/ ao fim. Use quando criar, iniciar, concluir ou listar planos; revisar estrutura de plan/; ou atribuir o proximo numero de plano. A skill e a dona da numeracao global e do indice.
metadata:
  camada: atividade
  escopo_negativo:
    - nao implementa o codigo das atividades planejadas
    - nao cria chamados (maintain-tickets)
    - nao conclui plano sem criterios de aceite verificados
  dependencias:
    - maintain-activities
    - maintain-tickets
  saidas:
    - criar-plano.ps1
    - validar-plano.ps1
    - concluir-plano.ps1
    - indice de planos regenerado
  triggers:
    - criar plano
    - concluir plano
    - iniciar plano
    - numerar plano
    - indice de planos
---

# Manter Planejador

## Objetivo

Manter o ciclo de vida de planos verificaveis no workspace `C:\codes`. A skill opera como CLIENTE da API do all_IA: desde o plano 000134 (casos 1-A/2-A), o BANCO e a fonte primaria dos planos - a pasta `NNNNNN-titulo-kebab/`, o `plano.md` e o indice `C:\codes\plan\indice-planos-{usuario}.json` sao ESPELHOS GERADOS pelo banco (marca "GERADO DO BANCO").

## Fonte primaria (000134)

1. CONSULTA: o indice oficial e `GET /plans/workspace/indice` (API all_IA); o JSON do disco e espelho de leitura para uso offline.
2. NUMERACAO: o proximo numero vem de `GET /plans/proximo-numero` (banco); o disco so e usado offline para gerar numero PROVISORIO.
3. ESCRITA: criar/iniciar/concluir/editar passam pela API (`POST /plans/workspace/criar`, `POST /plans/{n}/iniciar|concluir`, `PATCH /plans/{n}`); o banco grava e regenera plano.md + indice.
4. CONFLITO (caso 1-A): BANCO VENCE SEMPRE - edicao manual no plano.md e sobrescrita no proximo espelhamento; nao editar plano.md gerado.
5. OFFLINE (caso 6-A): somente leitura dos espelhos + FILA de escrita em `C:\codes\plan\.fila-pendente\*.jsonl`, drenada automaticamente no startup do backend (ou `POST /plans/fila/drenar`).

## Conceitos

- **Numero de plano**: inteiro sequencial global no workspace, formatado com 6 digitos (`000001`, `000002`, ...). Unico entre todos os `plan/`; alocado pelo BANCO (000134 caso 2-A).
- **Usuario do plano**: usuario atual da maquina no momento da criacao, lido de `C:\codes\personalizado.md` (`- Usuario atual: jz`, `jf`, etc.) e gravado no `plano.md` e no indice.
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
      "usuario_atual": "jz",
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

1. `proximo_numero` e sempre `max(numero) + 1` considerando **todas as linhas do banco** (em-andamento + concluidos + descartados) - fonte: `GET /plans/proximo-numero`.
2. `planos[]` lista **apenas** os com `status: em-andamento`.
3. O indice e REGENERADO PELO BANCO apos qualquer criar/iniciar/concluir/editar via API (000134); `scripts/atualizar-indice-planos.ps1` permanece apenas para reconstrucao manual a partir do disco (conciliacao/carga).
4. Todo plano novo deve gravar `- Usuario atual: <usuario>` no cabecalho, usando `personalizado.md` como fonte local da maquina.

## Status de plano

| Status | Onde fica | No indice? |
|---|---|---|
| `em-andamento` | `{plan_dir}/NNNNNN-.../` | sim |
| `concluido` | `{plan_dir}/concluido/NNNNNN-.../` | nao |
| `descartado` | `{plan_dir}/descartado/NNNNNN-.../` | nao |

## Regra obrigatoria de conclusao

1. Concluir plano sempre significa mover a pasta numerada `NNNNNN-titulo-kebab/` para `concluido/NNNNNN-titulo-kebab/` no mesmo `plan/` do contexto dono.
2. E proibido deixar plano com `Status: concluido` na pasta ativa do `plan/`.
3. Apos mover para `concluido/`, regenerar o indice do usuario; o plano concluido nao pode permanecer em `indice-planos-{usuario}.json`.
4. Se existir atividade bloqueada, pendente ou em andamento que nao possa ser executada localmente, registrar excecao objetiva na sessao e marcar a atividade como `cancelado` ou `bloqueado` antes da conclusao; nunca concluir sem explicar a excecao.
5. A verificacao minima de fechamento e: caminho ativo nao existe, caminho em `concluido/` existe, `plano.md` tem `Status: concluido` e o indice ativo nao lista o numero do plano.

## Uso

1. **Criar plano novo**: `scripts/criar-plano.ps1 -Titulo "meu plano" -Dono root|<empresa>|<empresa>/<projeto>|skill|tools/<tool>`. Pega o proximo numero, cria pasta, gera `plano.md` template, regenera indice do usuario corrente.
2. **Iniciar plano existente** (mudar status -> em-andamento): `scripts/iniciar-plano.ps1 -Numero NNNNNN`.
3. **Concluir plano**: `scripts/concluir-plano.ps1 -Numero NNNNNN`. Move obrigatoriamente a pasta numerada para `concluido/NNNNNN-.../`, atualiza `Status: concluido` e regenera o indice.
4. **Regenerar indice manualmente**: `scripts/atualizar-indice-planos.ps1 [-Usuario jz|jf]`.

## Limites

1. Nao criar plano fora do `plan/` do contexto dono.
2. Nao reutilizar numero (mesmo apos descartar).
3. Nao criar plano em-andamento sem chamado ativo vinculado (`chamado` no frontmatter).
4. Nao manter no indice planos concluidos/descartados.
5. Nao mover plano de uma pasta `plan/` para outra (numero acompanha contexto dono).
6. Nao criar regras de planejamento fora desta skill; tools sao apoio.
7. Nao concluir plano com atividades pendentes sem registrar excecao na sessao.
8. Nao permitir plano sem numeracao no nome (`NNNNNN-titulo-kebab`) em nenhum contexto.
9. Nao permitir criacao manual de arquivo avulso de plano fora da pasta numerada oficial.
10. Fora do proposito desta skill, devolver ao `route-skills-by-context` (nao improvisar).

## Fluxo

1. Ler `C:\codes\AGENTS.md` e `C:\codes\tools\planejador\AGENTS.md`.
2. Confirmar chamado ativo.
3. Executar `route-skills-by-context` e registrar na sessao ativa.
4. Decidir contexto dono do plano (root, empresa, projeto, skill, tool).
5. Para criar: chamar `criar-plano.ps1`; para concluir: `concluir-plano.ps1`.
6. Validar plano com `scripts/validar-plano.ps1`.
7. Indice e regenerado automaticamente; conferir `em_andamento_total`, `proximo_numero` e que o plano concluido nao aparece em `planos[]`.
8. Toda atividade executavel deve registrar: skills candidatas, skill executora, skills de apoio, motivo.
9. Reforcar processo basico antes da implementacao: sessao de chamado ativa -> plano numerado -> atividades com skills -> execucao tecnica.

## Scripts

1. `scripts/validar-plano.ps1`: valida estrutura minima de um `plano.md`.
2. `scripts/criar-plano.ps1 -Titulo <titulo> -Dono <root|empresa|empresa/projeto|skill|tools/tool> [-Prioridade N] [-Chamado <id>]`: cria via `POST /plans/workspace/criar` (numeracao do banco; espelhos gerados); offline = fila local com numero provisorio.
3. `scripts/iniciar-plano.ps1 -Numero <NNNNNN>`: `POST /plans/{n}/iniciar`; offline = fila.
4. `scripts/concluir-plano.ps1 -Numero <NNNNNN>`: `POST /plans/{n}/concluir` (banco muda status, move o espelho para `concluido/` e regenera o indice); offline = fila.
5. `scripts/atualizar-indice-planos.ps1 [-Usuario <jz|jf>]`: reconstrucao manual do indice a partir do DISCO (apenas conciliacao/carga inicial - no dia a dia o indice e gerado pelo banco).

## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa skill executora, skills de apoio, motivo da escolha e validacao.
3. Sem esse registro, manter atividade como `bloqueado`.
