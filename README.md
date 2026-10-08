# SYNTRA Radio

Plataforma profissional de automação, programação e operação de rádio para emissoras Web, FM e híbridas.

## Arquitetura

- `apps/control`: painel web/cloud em Next.js
- `apps/studio-engine`: motor local de playout, executado no computador da emissora
- `packages/contracts`: contratos compartilhados entre painel e motor
- `supabase/migrations`: banco, RLS e trilha de auditoria
- `docs`: decisões técnicas e arquitetura operacional

## Princípios

1. O áudio no ar não depende da internet nem da Vercel.
2. A nuvem coordena programação, biblioteca, usuários, auditoria e operação remota.
3. Cada organização tem isolamento de dados por RLS.
4. Estados vazios representam a realidade operacional; não há métricas fictícias.
5. Toda ação crítica deve ser auditável.
6. O Motor Local deve continuar executando a grade publicada mesmo quando a nuvem estiver indisponível.

## Estado atual

Fundação V0: painel operacional inicial, contratos do Studio Engine e schema multiempresa inicial.
