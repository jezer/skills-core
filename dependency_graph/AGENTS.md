# AGENTS - Skill Hierarchy Context

## Objetivo
1. Esta pasta faz parte da hierarquia oficial de skills em `C:\codes\skills`.
2. Toda mudanca persistente deve executar `route-skills-by-context` antes da implementacao.

## Regras
1. Nao duplicar proposito de skill existente.
2. Toda criacao/alteracao/exclusao/juncao/subskill deve consultar `core/skill_registry` e `core/dependency_graph`.
3. Sem registro de skill executora e skills de apoio na sessao ativa, atividade deve ficar bloqueada.
4. Regras especificas desta pasta prevalecem sobre regras genericas de `C:\codes\skills\AGENTS.md` no seu dominio.

## Validacao
1. Atualizar indices em `C:\codes\skills\indices` quando houver mudanca estrutural.
2. Executar sincronizador multi-IA apos mudancas em skills oficiais.
