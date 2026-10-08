import type { Metadata } from "next";
import "./styles.css";

export const metadata: Metadata = {
  title: "SYNTRA Radio",
  description: "Automação e operação profissional de rádio"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
