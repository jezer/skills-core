---
name: maintain-skills
description: Manter skills locais do workspace C:\codes somente quando o usuario solicitar explicitamente. Use para criar, revisar, mover, organizar ou validar skills em C:\codes\skills; processar sessoes pendentes relacionadas a manutencao de skills; mover sessoes concluidas para feitas; garantir que C:\Users mantenha somente a ponte global minima; ou coordenar `maintain-automations` quando atividades repetitivas puderem virar scripts, templates, assets ou referencias parametrizadas.
---

# Manter Skills

## Objetivo

Criar, revisar, organizar e validar skills locais em `C:\codes\skills`.

## Uso

1. Usar somente quando o usuario solicitar manutencao de skills.
2. Nao invocar automaticamente para tarefas comuns.
3. Processar apenas sessoes pendentes relacionadas a manutencao de skills.
4. Usar para alinhar skills com autonomia por contexto quando o usuario pedir atualizar principios de skills.

## Limites

1. Nao criar skills reais em `C:\Users\jezer.santos_nowvert\.codex\skills` nem em `C:\Users\jezer.santos_nowvert\.claude\skills`; esses diretorios sao pontes globais minimas ou nao existem para skills de workspace.
2. Nao carregar todas as skills por padrao.
3. Nao transformar `SKILL.md` em documentacao longa.
4. Nao criar arquivos auxiliares sem ganho operacional real.
5. Nao fazer skill alterar outro contexto diretamente; registrar pedido no `plan` do contexto dono quando necessario.
6. Nao apontar skill para tool global inexistente como dependencia obrigatoria.
7. Nao permitir que uma skill assuma proposito de outra skill ja existente.
8. Nao permitir que skills criem/editem planos diretamente fora da skill `maintain-planner`.
9. Nao criar skill fora do contexto dono (projeto, empresa ou root) definido para a manutencao.

## Fluxo

1. Ler `C:\codes\AGENTS.md`.
2. Ler `C:\codes\skills\AGENTS.md`.
3. Executar `route-skills-by-context` antes de qualquer mudanca persistente de skill e registrar na sessao ativa.
4. Criar skills reais somente em `C:\codes\skills`, dentro do subdiretorio de dominio correto (`core/`, `domains/`, `generators/`, `synchronizers/`); nunca criar SKILL.md diretamente na raiz de `C:\codes\skills`.
5. Manter em `C:\Users\jezer.santos_nowvert\.codex\skills` somente a ponte global minima `usar-codes-agents`, alem de pastas internas do sistema.
6. Escrever `SKILL.md` com frontmatter contendo somente `name` e `description`.
7. Manter o corpo da skill curto e operacional.
8. Validar toda skill alterada com `quick_validate.py`.
9. Ao concluir, completar a sessao pendente relacionada e mover para `sessoes/feitas/NNN.md`.
10. Para validar todas as skills locais, usar `scripts/validate-skills.ps1`.
11. Quando a atividade for repetitiva e mudar apenas parametros, usar `maintain-automations`.
12. Quando uma skill precisar de artefatos extensos ou reutilizaveis, planejar tool em `C:\codes\tools` e manter a skill curta.
13. Para gerar ou validar indices auxiliares de descoberta de skills, usar `scripts/atualizar-indices-skills.ps1`.
14. Depois de alterar skill oficial, revisar impacto em todos os destinos dist (`gemini`, `copilot`, `claude`, `codex`) e na ponte global do Codex (`codex_global`) para evitar divergencia de referencia.
15. Depois de criar/alterar skills, executar obrigatoriamente `scripts/validate-skills.ps1` para validar todas as skills do workspace antes de qualquer sincronizacao multi-IA.
16. Rodar `scripts/sincronizar-skills-ia.ps1` (sem `-Apply`) para verificar inconsistencias entre skills oficiais e os destinos; rodar com `-Apply` para copiar efetivamente `SKILL.md`, `agents/` e `scripts/` para `dist/gemini`, `dist/copilot`, `dist/claude`, `dist/codex` e `~/.codex/skills` somente apos validacao completa aprovada.
17. Ao final de toda manutencao de skills, executar sempre `scripts/finalizar-manutencao-skills.ps1` como comando unico de fechamento, sem perguntar confirmacao intermediaria.

## Regras

1. Atualizar skill existente quando a responsabilidade ja existir.
2. Criar skill nova apenas para atividade recorrente e bem delimitada.
3. Evitar duplicar regras que ja vivem em `AGENTS.md` ou em outra skill dona.
4. Nao criar sessao nova por conta propria quando nao houver pendente aberta para a atividade.
5. Preferir script, template ou asset dentro da skill dona quando o reaproveitamento depender apenas de parametros.
6. Preferir tool global para artefatos compartilhados entre contextos, depois de existir contrato aprovado em `C:\codes\tools`.
7. Se a melhoria de skill depender de outro contexto, registrar pedido no `plan` desse contexto.
8. Se nao houver skill aderente para uma execucao persistente, planejar a criacao ou revisao da skill antes da execucao.
9. Sempre registrar como a sincronizacao multi-IA (gemini, copilot, claude, codex, codex_global) foi tratada apos mudanca de skill (sem exigir duplicacao indevida de conteudo).
10. Quando o usuario pedir para "fazer sempre" o fechamento de qualidade, aplicar diretamente o comando unico final sem solicitar confirmacao extra.
11. Skills novas ou revisadas devem existir somente no contexto dono da demanda: projeto especifico, empresa especifica ou root.
12. Se a demanda de skill nao tiver contexto dono explicito, bloquear mudanca persistente ate definir se o destino e projeto, empresa ou root.
13. Qualquer movimento, renomeacao ou reorganizacao de pastas de skills exige obrigatoriamente:
   - atualizar indices em `C:\codes\skills\indices`;
   - revisar/atualizar referencias de caminho em scripts, workflows, planos e `AGENTS.md`;
   - rodar validacao completa (`validate-skills`, indices e sincronizador multi-IA) antes de concluir.
14. Ordem obrigatoria de fechamento de manutencao de skill: `validar skills` -> `validar indices` -> `sincronizar IA`; nunca sincronizar IA antes da validacao das skills.
15. Antes de aceitar skill vinda de clone externo (`git clone`, `gh repo clone`, sincronizacao de indice peer), comparar conteudo com versao em `core/` ou `domains/`; se for snapshot legado/duplicata, nao aceitar e registrar pedido de delete do repositorio remoto.
16. Skills oficiais nao tem repositorio Git proprio nem URL remota dedicada; rejeitar qualquer pedido de criar `jezer/skill-<nome>.git` ou similar.
17. Ao remover skill duplicata ou legada, aplicar checklist de propagacao multi-maquina: (a) `rm` da pasta local em toda maquina (`jz`, `jf`); (b) `gh repo delete` do remoto se houver; (c) regerar `indice-repositorios-root-<maquina>.json` em toda maquina; (d) commit + push do indice atualizado; (e) rodar `sincronizar-skills-ia.ps1 -Apply` para limpar destinos `dist/`.
18. Auditoria periodica: o `revisor-periodico-skills` deve detectar e abrir pedido para qualquer skill em `C:\codes\skills\<nome>` (raiz) que nao seja repo canonico (`core`, `dist`, `domains`, `generators`, `git-user`, `indices`, `plan`, `reports`, `scripts`, `synchronizers`).

## Scripts

1. `scripts/validate-skills.ps1`: valida todos os diretorios em `C:\codes\skills` que possuem `SKILL.md`. Flags: `-AutoFixBom` remove BOM UTF-8 antes da validacao; `-ContinueOnError` reporta tudo sem abortar; `-ReportPath <caminho>` salva relatorio JSON com categoria de cada falha (`frontmatter-missing`, `yaml-invalid`, `description-angle-brackets`, `description-too-long`, `name-format`, `name-too-long`, `field-missing`, `unexpected-key`, `outro`).
2. `scripts/atualizar-indices-skills.ps1`: gera ou valida indices auxiliares em `C:\codes\skills\indices`.
3. Quando necessario, usar `configure-machine-default-skill` para validar a ponte global minima do Codex.
4. `scripts/sincronizar-skills-ia.ps1`: sem `-Apply` exibe divergencias (missing/extras) entre skills oficiais e os 5 destinos (gemini, copilot, claude, codex, codex_global) e valida a ponte Codex; com `-Apply` copia todos os arquivos (`SKILL.md`, `agents/`, `scripts/`) para cada destino.
5. `scripts/finalizar-manutencao-skills.ps1`: comando unico final e obrigatorio, executando nesta ordem: validacao de skills, validacao de indices e sincronizacao IA.


## Correlacao Obrigatoria de Skills

1. Antes de qualquer mudanca persistente, executar `route-skills-by-context`.
2. Registrar na sessao ativa:
- skill executora
- skills de apoio
- motivo da escolha
- validacao da escolha
3. Sem esse registro, manter atividade como `bloqueado`.
