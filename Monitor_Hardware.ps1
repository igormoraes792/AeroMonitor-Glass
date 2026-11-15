# ==============================================================================
# MONITOR DE HARDWARE GLASS - INTERFACE MODERNA E TELEMETRIA EM TEMPO REAL
# ==============================================================================
# Executa servidor local ultraleve e abre uma janela estilo Desktop App (Glassmorphism).
# Grava todas as metricas no arquivo CSV a cada 1 segundo com AutoFlush imediato.
# Se o computador desligar por superaquecimento ou corte, o log esta seguro no disco.
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'SilentlyContinue'

$pastaExecucao = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$dataInicio = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$nomeCsv = "hardware_log_$dataInicio.csv"
$arquivoLog = Join-Path $pastaExecucao $nomeCsv
$htmlFile = Join-Path $pastaExecucao "app_ui\index.html"

# Inicializa o gravador de CSV com gravacao direta no disco
$stream = [System.IO.FileStream]::new($arquivoLog, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
$writer = [System.IO.StreamWriter]::new($stream, [System.Text.Encoding]::UTF8)
$writer.AutoFlush = $true

$cabecalho = "Data_Hora;CPU_Uso_Pct;CPU_Clock_MHz;CPU_Limite_Desempenho_Pct;RAM_Usada_GB;RAM_Total_GB;RAM_Uso_Pct;GPU_Uso_Pct;VRAM_Usada_MB;Disco_Uso_Pct;Top_Processo_RAM;Top_Processo_CPU_Historico"
$writer.WriteLine($cabecalho)

# Detecta o caminho dinamico do clock da CPU
$freqCounterPath = $null
try {
    $procSet = Get-Counter -ListSet "*Informações do Processador*", "*Processor Information*" -ErrorAction SilentlyContinue
    if ($procSet) {
        $freqCounterPath = ($procSet.PathsWithInstances | Where-Object { $_ -match "\(_Total\)" -and ($_ -match "Frequ" -or $_ -match "Freq") }) | Select-Object -First 1
    }
} catch {}

# Inicia servidor web local para servir a interface Glassmorphism
$port = 5892
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$port/")
try {
    $listener.Start()
} catch {
    $port = 5893
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://127.0.0.1:$port/")
    $listener.Start()
}

# Abre o aplicativo no modo de janela isolada (Edge App Mode)
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edgePath) {
    Start-Process $edgePath -ArgumentList "--app=http://127.0.0.1:$port/", "--window-size=1360,860", "--window-position=60,60"
} else {
    Start-Process "http://127.0.0.1:$port/"
}

# Variaveis globais de estado
$global:latestJson = "{}"
$osInfo = Get-CimInstance Win32_OperatingSystem -Property TotalVisibleMemorySize
$totalRamGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
$running = $true

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                AEROMONITOR GLASS - INTERFACE GRÁFICA ATIVA                     " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Servidor local: http://127.0.0.1:$port/" -ForegroundColor Green
Write-Host " Salvando log em: $arquivoLog" -ForegroundColor White
Write-Host " Para encerrar: Feche a janela da interface ou pressione [Q] aqui no console." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

# Tarefa assincrona de escuta HTTP
$contextTask = $listener.GetContextAsync()

try {
    while ($running) {
        $agora = Get-Date
        $timestamp = $agora.ToString("yyyy-MM-dd HH:mm:ss.fff")

        # 1. Metricas de CPU
        $cpuInfo = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name = '_Total'" -Property PercentProcessorTime, PercentPerformanceLimit
        $cpuUsage = if ($cpuInfo) { $cpuInfo.PercentProcessorTime } else { 0 }
        $perfLimit = if ($cpuInfo) { $cpuInfo.PercentPerformanceLimit } else { 100 }

        $clockMHz = 0
        if ($freqCounterPath) {
            try {
                $sample = (Get-Counter -Counter $freqCounterPath -ErrorAction Stop).CounterSamples[0].CookedValue
                $clockMHz = [math]::Round($sample, 0)
            } catch {}
        }
        if ($clockMHz -eq 0) {
            try {
                $clockMHz = (Get-CimInstance Win32_Processor -Property CurrentClockSpeed).CurrentClockSpeed
            } catch { $clockMHz = 3600 }
        }

        # 2. Metricas de RAM
        $osMem = Get-CimInstance Win32_OperatingSystem -Property FreePhysicalMemory
        $freeRamGB = [math]::Round($osMem.FreePhysicalMemory / 1MB, 2)
        $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
        $ramPct = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

        # 3. Metricas de GPU & VRAM (DedicatedUsage da RX 6600 XT)
        $gpuUsage = 0
        try {
            $gpuSamples = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -Property UtilizationPercentage
            $maxUtil = ($gpuSamples | Measure-Object -Property UtilizationPercentage -Maximum).Maximum
            $gpuUsage = [math]::Min(100, [math]::Round($maxUtil, 0))
        } catch {}

        $vramMB = 0
        try {
            $vramAdapters = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory -Property DedicatedUsage
            $dedicatedBytes = ($vramAdapters | Measure-Object -Property DedicatedUsage -Sum).Sum
            $vramMB = [math]::Round($dedicatedBytes / 1MB, 0)
        } catch {}

        # 4. Disco
        $diskInfo = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name = '_Total'" -Property PercentDiskTime
        $diskUsage = if ($diskInfo) { $diskInfo.PercentDiskTime } else { 0 }

        # 5. Processos mais pesados (RAM e CPU)
        $topMemProc = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 1
        $topMemName = if ($topMemProc) { $topMemProc.ProcessName } else { "N/A" }
        $topMemMB = if ($topMemProc) { [math]::Round($topMemProc.WorkingSet64 / 1MB, 0) } else { 0 }
        $topMemString = "$topMemName ($topMemMB MB)"

        $topCpuProc = Get-Process | Where-Object { $_.Id -ne 0 -and $_.ProcessName -ne "Idle" } | Sort-Object CPU -Descending | Select-Object -First 1
        $topCpuName = if ($topCpuProc) { $topCpuProc.ProcessName } else { "N/A" }
        $topCpuSec = if ($topCpuProc) { [math]::Round($topCpuProc.CPU, 0) } else { 0 }
        $topCpuString = "$topCpuName (${topCpuSec}s)"

        # Grava imediatamente no CSV (AutoFlush ativo)
        $linha = "$timestamp;$cpuUsage;$clockMHz;$perfLimit;$usedRamGB;$totalRamGB;$ramPct;$gpuUsage;$vramMB;$diskUsage;$topMemString;$topCpuString"
        $writer.WriteLine($linha)

        # Atualiza o JSON entregue para a interface gráfica
        $dataObj = @{
            cpu         = $cpuUsage
            clock       = $clockMHz
            perfLimit   = $perfLimit
            ramUsed     = $usedRamGB
            ramFree     = $freeRamGB
            ramTotal    = $totalRamGB
            ramPct      = $ramPct
            gpu         = $gpuUsage
            vramMB      = $vramMB
            disk        = $diskUsage
            topProc     = $topMemString
            topMemName  = $topMemName
            topMemMB    = $topMemMB
            topCpuName  = $topCpuName
            topCpuSec   = $topCpuSec
            csvFile     = $nomeCsv
        }
        $global:latestJson = ($dataObj | ConvertTo-Json -Compress)

        # Processa requisicoes HTTP pendentes da interface
        $loopStart = [System.Diagnostics.Stopwatch]::StartNew()
        while ($loopStart.ElapsedMilliseconds -lt 1000) {
            if ($contextTask.IsCompleted) {
                try {
                    $context = $contextTask.Result
                    $reqPath = $context.Request.Url.AbsolutePath
                    $response = $context.Response

                    if ($reqPath -eq "/" -or $reqPath -eq "/index.html") {
                        $htmlContent = if (Test-Path $htmlFile) { [System.IO.File]::ReadAllBytes($htmlFile) } else { [System.Text.Encoding]::UTF8.GetBytes("<h1>UI nao encontrada</h1>") }
                        $response.ContentType = "text/html; charset=utf-8"
                        $response.ContentLength64 = $htmlContent.Length
                        $response.OutputStream.Write($htmlContent, 0, $htmlContent.Length)
                        $response.OutputStream.Close()
                    } elseif ($reqPath -eq "/api/metrics") {
                        $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($global:latestJson)
                        $response.ContentType = "application/json; charset=utf-8"
                        $response.ContentLength64 = $jsonBytes.Length
                        $response.OutputStream.Write($jsonBytes, 0, $jsonBytes.Length)
                        $response.OutputStream.Close()
                    } elseif ($reqPath -eq "/api/open-folder") {
                        Start-Process "explorer.exe" -ArgumentList "`"$pastaExecucao`""
                        $okBytes = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok"}')
                        $response.ContentType = "application/json"
                        $response.OutputStream.Write($okBytes, 0, $okBytes.Length)
                        $response.OutputStream.Close()
                    } elseif ($reqPath -eq "/api/stop") {
                        $okBytes = [System.Text.Encoding]::UTF8.GetBytes('{"status":"stopped"}')
                        $response.ContentType = "application/json"
                        $response.OutputStream.Write($okBytes, 0, $okBytes.Length)
                        $response.OutputStream.Close()
                        $running = $false
                    } else {
                        $response.StatusCode = 404
                        $response.OutputStream.Close()
                    }
                } catch {}

                $contextTask = $listener.GetContextAsync()
            }
            Start-Sleep -Milliseconds 50
        }

        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Q) {
                $running = $false
                break
            }
        }
    }
}
finally {
    if ($writer) {
        $writer.Flush()
        $writer.Close()
        $writer.Dispose()
    }
    if ($stream) {
        $stream.Close()
        $stream.Dispose()
    }
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        $listener.Close()
    }
    Write-Host "`nMonitoramento finalizado e log salvo com sucesso em: $arquivoLog" -ForegroundColor Green
}
