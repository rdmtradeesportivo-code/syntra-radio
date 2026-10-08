const navigation = [
  "Central de operação",
  "Programação",
  "Biblioteca",
  "Playlists",
  "Comercial",
  "Emissoras",
  "Motor local",
  "Logs"
];

function Status({
  label,
  value,
  tone = "neutral"
}: {
  label: string;
  value: string;
  tone?: "neutral" | "danger" | "success";
}) {
  return (
    <div className="statusItem">
      <span className={"statusDot " + tone} />
      <div>
        <small>{label}</small>
        <strong>{value}</strong>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <div className="appShell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brandMark">S</div>
          <div>
            <strong>SYNTRA</strong>
            <span>RADIO</span>
          </div>
        </div>

        <nav>
          {navigation.map((item, index) => (
            <a key={item} className={index === 0 ? "active" : ""}>
              <span className="navIndex">{String(index + 1).padStart(2, "0")}</span>
              {item}
            </a>
          ))}
        </nav>

        <div className="sidebarFooter">
          <span className="envDot" />
          Fundação V0
        </div>
      </aside>

      <main className="workspace">
        <header className="topbar">
          <div>
            <span className="eyebrow">CENTRAL DE OPERAÇÃO</span>
            <h1>Visão da emissora</h1>
            <p>Estado operacional real do ambiente de transmissão.</p>
          </div>
          <button className="primaryButton">Configurar emissora</button>
        </header>

        <section className="statusStrip">
          <Status label="MOTOR LOCAL" value="Não conectado" tone="danger" />
          <Status label="SAÍDA PRINCIPAL" value="Não configurada" />
          <Status label="STREAMING" value="Não configurado" />
          <Status label="ÚLTIMA SINCRONIZAÇÃO" value="—" />
        </section>

        <section className="primaryGrid">
          <article className="card onAirCard">
            <div className="sectionHeader">
              <div>
                <span className="eyebrow">NO AR</span>
                <h2>Nenhuma reprodução ativa</h2>
              </div>
              <span className="badge">OFFLINE</span>
            </div>

            <div className="waveform" aria-hidden="true">
              {Array.from({ length: 34 }).map((_, index) => (
                <i key={index} />
              ))}
            </div>

            <p className="muted">
              Conecte o Motor Local para liberar o playout. O painel cloud nunca assume
              a saída de áudio sem um agente autorizado na emissora.
            </p>
          </article>

          <article className="card">
            <div className="sectionHeader">
              <div>
                <span className="eyebrow">FILA</span>
                <h2>Próximos itens</h2>
              </div>
              <span className="counter">0 itens</span>
            </div>
            <div className="emptyState">
              <div className="emptySymbol">+</div>
              <strong>A fila está vazia</strong>
              <span>A programação aparecerá após a primeira grade ser publicada.</span>
            </div>
          </article>
        </section>

        <section className="secondaryGrid">
          <article className="card">
            <div className="sectionHeader">
              <div>
                <span className="eyebrow">IMPLANTAÇÃO</span>
                <h2>Preparar primeira emissora</h2>
              </div>
              <span className="counter">0 / 4</span>
            </div>

            <div className="steps">
              {[
                ["01", "Cadastrar emissora", "Nome, fuso, perfil Web/FM e saída principal."],
                ["02", "Instalar Motor Local", "Vincular a máquina responsável pelo áudio."],
                ["03", "Importar biblioteca", "Músicas, vinhetas, spots e programas."],
                ["04", "Publicar primeira grade", "Programar, validar e testar o failover."]
              ].map(([number, title, description]) => (
                <div className="step" key={number}>
                  <span>{number}</span>
                  <div>
                    <strong>{title}</strong>
                    <p>{description}</p>
                  </div>
                  <button disabled>pendente</button>
                </div>
              ))}
            </div>
          </article>

          <article className="card">
            <span className="eyebrow">SAÚDE OPERACIONAL</span>
            <h2>Pré-requisitos</h2>
            <div className="healthList">
              <div><span>Cloud</span><strong className="ok">Disponível</strong></div>
              <div><span>Motor local</span><strong>Não vinculado</strong></div>
              <div><span>Dispositivo de áudio</span><strong>Não detectado</strong></div>
              <div><span>Streaming</span><strong>Não configurado</strong></div>
            </div>
          </article>
        </section>
      </main>
    </div>
  );
}
