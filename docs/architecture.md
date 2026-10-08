# Arquitetura — SYNTRA Radio

## 1. Separação essencial

O produto possui duas camadas independentes:

### Control Cloud
Responsável por autenticação, cadastro de emissoras, biblioteca, programação, OPEC, auditoria, telemetria e operação remota.

### Studio Engine
Executado localmente na emissora. Responsável por cache de mídia, fila publicada, dispositivos de áudio, playout, transições, entradas ao vivo, gravação e integração com encoder/streaming.

A indisponibilidade temporária do Control Cloud não pode interromper o áudio em execução.

## 2. Fluxo operacional

1. O operador cria ou altera uma grade no Control Cloud.
2. A grade é validada e publicada como uma revisão imutável.
3. O Studio Engine sincroniza a revisão e o conteúdo necessário.
4. O motor valida integridade/hash e mantém cache local.
5. O playout é executado localmente.
6. Eventos de reprodução são enviados para a nuvem com chaves idempotentes.
7. Em perda de conexão, os eventos ficam em fila local até a reconexão.

## 3. Segurança

- Multiempresa por organização.
- RLS em todas as tabelas expostas.
- Nenhum acesso anônimo ao domínio operacional.
- Chave de serviço nunca é enviada ao navegador.
- Motor Local terá identidade de dispositivo própria e revogável.
- Toda operação administrativa crítica gera audit log.
- Segredos de streaming ficam fora do cliente web.

## 4. Roadmap técnico

### V0 — Fundação
Painel, banco, autenticação, emissoras, biblioteca, playlists, programação, eventos e contrato do Motor Local.

### V1 — Playout
Dispositivos de áudio, dois decks, cue, crossfade, auto-next, cache local, watchdog e recuperação.

### V2 — Operação
Comerciais/OPEC, cartucheira, hora certa, entradas ao vivo, voice track, gravação/logger e relatórios.

### V3 — Distribuição
Streaming, rádio visual, integração OBS/vMix, operação remota e afiliadas.
