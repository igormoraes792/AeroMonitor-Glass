# 📜 Histórico de Desenvolvimento e Decisões Técnicas — AeroMonitor Glass

Este documento reúne todo o histórico da conversa, diagnósticos de hardware, calibragens de contadores e decisões de arquitetura desenvolvidos durante a criação do **AeroMonitor Glass**.

---

## 1. Contexto Inicial e Diagnóstico de Quedas

* **Problema Relatado:** Computador desligando repentinamente durante jogos (Overwatch, Hogwarts Legacy, etc.).
* **Hardware do Usuário:**
  * **Processador:** AMD Ryzen 7 5700X 8-Core Processor (3.6 GHz Base / 4.6 GHz Boost).
  * **Placa de Vídeo:** AMD Radeon RX 6600 XT (8.192 MB GDDR6 VRAM dedicada).
  * **Memória RAM:** 32 GB DDR4 (31.91 GB visíveis no SO).
* **Diagnóstico de Segurança:**
  * Realizada varredura de processos ocultos, tarefas agendadas e conexões suspeitas à procura de trojans ou mineradores de criptomoeda.
  * O sistema foi atestado como 100% limpo de malware.
  * O histórico de Eventos do Windows (Event ID 41 / 1074) indicou que os desligamentos eram de corte abrupto de energia, típicos de limite de temperatura (Thermal Shutdown) ou pico de consumo da fonte de alimentação.

---

## 2. Requisitos do Monitor de Hardware

1. **Zero Perda de Dados (Anti-Crash):**
   * Monitores padrão perdem os últimos 15 a 30 segundos de log quando o PC desliga da tomada devido ao cache em buffer de memória.
   * **Solução:** Implementação do modo [System.IO.StreamWriter] com AutoFlush = True, forçando gravação física no SSD segundo a segundo.
2. **Execução Autônoma e Nativa:**
   * Sem download de executáveis externos ou instaladores pesados da internet.
   * Utilização exclusiva de APIs nativas do Windows: WDDM 2.0+ Performance Counters, WMI CIM, Get-Counter e .NET HttpListener.
3. **Interface Visual Dark Glassmorphism:**
   * Inspirada no design Kerfa (vidro escuro translúcido com ackdrop-filter: blur(28px)).
   * Execução em modo aplicativo desktop sem barras nem abas de navegador (msedge.exe --app).

---

## 3. Calibragem dos Contadores de Telemetria

* **Memória de Vídeo (VRAM):**
  * *Primeira tentativa:* Uso de TotalCommitted reportou ~7.6 GB quando a AMD mostrava 6.0 GB (incluía memória virtual compartilhada).
  * *Segunda tentativa:* Uso de LocalUsage reportou ~5.3 GB quando o jogo consumia ~7.9 GB (apenas segmento local de paginação).
  * *Calibragem Definitiva:* Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory -> DedicatedUsage. Mede com precisão exata de 1 MB a alocação física da VRAM dedicada, batendo 1:1 com o software oficial AMD Adrenalin.
* **Carga da Placa de Vídeo (GPU %):**
  * Somar todos os motores (GPUEngine) causava valores irreais (>100%, ex: 122%).
  * *Calibragem Definitiva:* Cálculo da carga máxima instantânea (-Maximum) entre os motores ativos, limitado a 100%.
* **Frequência e Throttling da CPU:**
  * Resolução dinâmica do contador de frequência para evitar quebras de codificação UTF-8 em PowerShell 5.1/7.
  * Monitoramento do contador % de Desempenho Máximo da CPU para acusar na hora cortes térmicos impostos pela placa-mãe.

---

## 4. Evolução da Interface Gráfica (Glassmorphism)

* **Organização em 4 Colunas Rígidas por Hardware:**
  1. Processador (CPU)
  2. Placa de Vídeo (GPU)
  3. Memória RAM
  4. Armazenamento (Disco / SSD)
* **Gráficos Sparkline em Tempo Real:**
  * Canvas HTML5 renderizando curvas de Bézier cúbicas a 60 FPS com gradiente temático e ponto de leitura ativo.
* **5 Temas de Cores:**
  * Laranja (Warm Coral), Azul (Cyber Ice), Verde (Matrix Emerald), Amarelo (Cyber Amber) e Roxo (Synthwave Violet), com persistência em localStorage.
* **Destaques de Alto Impacto (Glow Alerts):**
  * Detecção de sobrecarga por componente:
    * CPU ≥ 75% ou Throttling < 100% -> Alerta vermelho com nome do processo em destaque.
    * GPU ≥ 80% ou VRAM ≥ 85% -> Alerta de carga intensa ou gargalo de memória gráfica.
    * RAM ≥ 80% -> Destaque indicando o software que mais consome RAM.
    * Disco ≥ 85% -> Alerta de fila de I/O em saturação.

---

## 5. Versionamento e Publicação no GitHub

* **Repositório:** [https://github.com/igormoraes792/AeroMonitor-Glass](https://github.com/igormoraes792/AeroMonitor-Glass)
* **Branch:** main
* **Licença:** MIT
* **Arquivos do Projeto:**
  * INICIAR_MONITORAMENTO.bat: Launcher de 1 clique
  * Monitor_Hardware.ps1: Servidor HTTP local e coletor WDDM
  * pp_ui/index.html: Interface visual Glassmorphism
  * README.md: Apresentação completa e guia de uso
  * .gitignore: Proteção para não commitar logs de crash .csv
  * LICENSE: Licença de software livre
