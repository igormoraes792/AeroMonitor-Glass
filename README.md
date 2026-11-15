# 💎 AeroMonitor Glass

> **Monitor de Telemetria de Hardware em Tempo Real com Interface Dark Glassmorphism e Proteção contra Desligamento Abrupto (Anti-Crash).**

![AeroMonitor Glass](https://img.shields.io/badge/Plataforma-Windows%2010%20%7C%2011-blue?style=for-the-badge&logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207+-1f425f?style=for-the-badge&logo=powershell)
![Interface](https://img.shields.io/badge/UI-Dark%20Glassmorphism-e88662?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Est%C3%A1vel-success?style=for-the-badge)

---

## 📸 Sobre o Projeto

O **AeroMonitor Glass** foi desenvolvido para monitorar o hardware do computador segundo a segundo durante jogos ou tarefas pesadas, com foco em descobrir **o motivo exato de desligamentos repentinos, travamentos ou cortes térmicos (*thermal throttling*)**.

Diferente de monitores convencionais que perdem os últimos 10 a 30 segundos de log quando a máquina apaga da tomada, o AeroMonitor utiliza o modo **`AutoFlush` imediato no SSD**: cada linha de métrica é forçada fisicamente para o disco a cada 1 segundo. Se o PC desligar, o último segundo antes da queda estará salvo no arquivo `.csv`.

---

## ✨ Principais Funcionalidades

* 🎨 **Interface Dark Glassmorphism:**
  - Painéis translúcidos em vidro escuro com desfoque profundo (`backdrop-filter: blur(28px)`), iluminação ambiente dinâmica e estética inspirada em painéis modernos de telemetria.
  - Execução como **Desktop App nativo** (via Microsoft Edge App Mode, sem abas nem barras de navegador).

* 🌈 **5 Temas de Cores Selecionáveis:**
  - 🟠 **Laranja (Warm Coral):** Tema aconchegante original.
  - 🔵 **Azul (Cyber Ice):** Tema azul elétrico e ciano neon.
  - 🟢 **Verde (Matrix Emerald):** Verde esportivo vibrante.
  - 🟡 **Amarelo (Cyber Amber):** Âmbar dourado de alto contraste.
  - 🟣 **Roxo (Synthwave Violet):** Roxo neon moderno.
  - *Memória automática:* O tema escolhido fica gravado e é lembrado nas próximas aberturas.

* 📊 **4 Colunas Estritamente Organizadas por Hardware:**
  1. **Processador (CPU):** Uso geral (%), frequência real em MHz (ex: 3.600 MHz) e indicador dinâmico de **Saúde Térmica & Throttling** (100% Seguro ou Alerta de Aquecimento).
  2. **Placa de Vídeo (GPU):** Carga do motor 3D em tempo real e monitoramento preciso de **VRAM Dedicada** (em MB e % alocada dos 8.192 MB físicos).
  3. **Memória RAM:** Uso total em GB e %, memória livre e identificador do **aplicativo mais pesado no momento**.
  4. **Armazenamento (Disco / SSD):** Porcentagem de atividade I/O de leitura/escrita, status do arquivo CSV e atalhos rápidos de abertura.

* 🚨 **Destaque Visual de Alto Impacto:**
  - Quando qualquer componente de hardware sofre sobrecarga (CPU > 75%, GPU > 80%, VRAM > 85%, RAM > 80% ou Disco > 85%), o card e a pílula correspondente passam a pulsar em vermelho com brilho de alerta, indicando na hora qual processo está causando o impacto.

* 🛡️ **Zero Perda em Desligamento Abrupto:**
  - Gravação contínua em formato `.csv` com descarga física direta (`AutoFlush = $true`), compatível com Excel, PowerBI ou Google Sheets.

---

## 🚀 Como Executar

### Pré-requisitos:
- Sistema Operacional: **Windows 10 ou Windows 11 (64 bits)**
- PowerShell (compatível com Windows PowerShell 5.1 e PowerShell 7+)
- Navegador Microsoft Edge (já pré-instalado no Windows)

### Passo a Passo:
1. Baixe ou clone este repositório:
   ```bash
   git clone https://github.com/igormoraes792/AeroMonitor-Glass.git
   ```
2. Dê duplo clique no arquivo:
   👉 **`INICIAR_MONITORAMENTO.bat`**
3. A janela de monitoramento em tempo real se abrirá na tela e o arquivo de log `.csv` começará a ser preenchido no mesmo diretório.
4. Para encerrar, basta fechar a janela ou clicar em **Parar**.

---

## 📁 Estrutura de Arquivos

```text
AeroMonitor-Glass/
├── INICIAR_MONITORAMENTO.bat    # Inicializador de 1 clique
├── Monitor_Hardware.ps1        # Backend em PowerShell (servidor local e telemetria)
├── .gitignore                  # Ignora arquivos de log CSV e temporários
├── README.md                   # Documentação do projeto
└── app_ui/
    └── index.html              # Frontend Glassmorphism moderno (HTML5 + CSS + JS)
```

---

## 🛠️ Tecnologias Utilizadas

- **PowerShell / .NET:** Coleta de contadores de desempenho nativos (`Win32_PerfFormattedData`, `Get-Counter`, `Win32_OperatingSystem`, WDDM 2.0+).
- **Servidor Local Ultraleve:** `System.Net.HttpListener` local sem dependências externas.
- **Frontend Moderno:** HTML5, CSS3 Glassmorphism (`backdrop-filter`), Canvas API para gráficos Sparkline de 60 FPS com curvas suaves de Bézier.

---

## 👤 Autor

Criado por **Igor Moraes**  
GitHub: [@igormoraes792](https://github.com/igormoraes792)

---

## 📄 Licença

Este projeto está sob a licença [MIT](LICENSE).
