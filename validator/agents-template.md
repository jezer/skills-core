# AGENTS Template - Hierarchy

## Objetivo
1. Declarar finalidade da pasta no sistema de skills.
2. Garantir roteamento e governanca obrigatorios.

## Regras Minimas
1. Executar `route-skills-by-context` antes de mudanca persistente.
2. Registrar skill executora, apoio, motivo e validacao na sessao.
3. Nao duplicar proposito de skill existente.
4. Consultar `core/skill_registry` e `core/dependency_graph` em mudancas de ciclo de vida de skill.

## Validacao
1. Atualizar indices apos mudanca estrutural.
2. Rodar validacoes de skill e sincronizacao multi-IA.
