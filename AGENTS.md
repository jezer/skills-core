# AGENTS - Skill Hierarchy Context

## Objetivo
1. Esta pasta faz parte da hierarquia oficial de skills em `C:\codes\skills`.
2. Toda mudanca persistente deve executar `route-skills-by-context` antes da implementacao.

## Regras
1. Nao duplicar proposito de skill existente.
2. Toda criacao/alteracao/exclusao/juncao/subskill deve consultar `core/skill_registry` e `core/dependency_graph`.
3. Sem registro de skill executora e skills de apoio na sessao ativa, atividade deve ficar bloqueada.
4. Regras especificas desta pasta prevalecem sobre regras genericas de `C:\codes\skills\AGENTS.md` no seu dominio.

## Anti-duplicacao e topologia de skills
1. Skill oficial mora obrigatoriamente em subdiretorio canonico do dominio: `core/`, `domains/`, `generators/` ou `synchronizers/`. Nunca como pasta-irma direta em `C:\codes\skills\<nome>`.
2. Skill oficial nao tem repositorio Git proprio nem URL remota dedicada (`jezer/skill-*`); skills sao pastas comuns dentro dos repos pai (`skills-core`, `skills-domains`, `skills-generators`, `skills-synchronizers`).
3. Antes de aceitar skill vinda de clone externo (`git clone`, `gh repo clone`, sincronizacao de indice peer), comparar conteudo com versao em `core/` ou `domains/`; se for snapshot legado/duplicata, rejeitar e abrir pedido de delete remoto.
4. Remocao de skill duplicata ou legada exige propagacao multi-maquina obrigatoria: (a) `rm` da pasta local em toda maquina (`jz`, `jf`); (b) `gh repo delete` do remoto se houver; (c) regerar `indice-repositorios-root-<maquina>.json` em toda maquina; (d) commit + push do indice atualizado; (e) `sincronizar-skills-ia.ps1 -Apply` para limpar destinos `dist/`.
5. Repositorios remotos com nome `jezer/skill-<nome>` sao tratados como legado; auditoria periodica via `revisor-periodico-skills` deve flagar e propor consolidacao em `core/` ou `domains/`.

## Validacao
1. Atualizar indices em `C:\codes\skills\indices` quando houver mudanca estrutural.
2. Executar sincronizador multi-IA apos mudancas em skills oficiais.
