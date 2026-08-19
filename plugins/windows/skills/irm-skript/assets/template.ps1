<#
  TOOLNAME - Kurzbeschreibung in einem Satz

  Aufruf (elevated PowerShell, echtes Terminal):
      irm labi.dev/ROUTE | iex
#>

function Start-ToolName {

    $script:Width = 64
    try { $w = [Console]::WindowWidth; if ($w -gt 0) { $script:Width = [Math]::Max(40, [Math]::Min(64, $w - 4)) } } catch {}

    $script:Interactive = $true
    try { if ([Console]::IsInputRedirected) { $script:Interactive = $false } } catch { $script:Interactive = $false }

    # ----------------------------------------------------------------
    # Eingabe
    # ----------------------------------------------------------------
    function Read-Key {
        try { $ki = [Console]::ReadKey($true) }
        catch { return 'QUIT' }
        if (($ki.Modifiers -band [ConsoleModifiers]::Control) -and $ki.Key -eq 'C') { return 'QUIT' }
        switch ($ki.Key) {
            'Enter'      { return 'ENTER' }
            'Escape'     { return 'B' }
            'RightArrow' { return 'RIGHT' }
            'LeftArrow'  { return 'LEFT'  }
            'Spacebar'   { return 'SPACE' }
            default      { return $ki.KeyChar.ToString().ToUpper() }
        }
    }
    function Wait-Key { if ($script:Interactive) { try { [void][Console]::ReadKey($true) } catch {} } }

    # ----------------------------------------------------------------
    # Ausgabe-Helfer
    # ----------------------------------------------------------------
    function Write-Line  { param([string]$Text='',[string]$Color='Gray') Write-Host $Text -ForegroundColor $Color }
    function Write-Blank { Write-Host '' }
    function Write-Rule  { Write-Host ('  ' + ('-' * $script:Width)) -ForegroundColor DarkCyan }

    function Write-Header {
        if ($script:Interactive) { Clear-Host }
        Write-Blank
        Write-Host '   TOOLNAME   Untertitel' -ForegroundColor Cyan
        Write-Host '   by Sven Labitzki' -ForegroundColor DarkGray
        Write-Rule
        $sys = $script:System
        if ($null -ne $sys) {
            Write-Host ("   {0}   |   {1}" -f $sys.ComputerName, $sys.OS) -ForegroundColor DarkGray
        }
        Write-Blank
    }

    function Write-StatusRow {
        param([string]$Label,[string]$State)
        switch ($State) {
            'done'    { $badge='[ OK ]'; $color='Green' }
            'running' { $badge='[ >> ]'; $color='Cyan' }
            'failed'  { $badge='[ !! ]'; $color='Red' }
            'warn'    { $badge='[ ~~ ]'; $color='Yellow' }
            default   { $badge='[ -- ]'; $color='DarkGray' }
        }
        $pad = [Math]::Max(1, $script:Width - $Label.Length - $badge.Length)
        Write-Host ('   ' + $Label) -ForegroundColor Gray -NoNewline
        Write-Host (' ' * $pad) -NoNewline
        Write-Host $badge -ForegroundColor $color
    }

    function Write-MenuCell {
        param([string]$Key,[string]$Label,[string]$KeyColor='Cyan',[int]$Cell=22)
        Write-Host "[$Key] " -ForegroundColor $KeyColor -NoNewline
        Write-Host $Label -ForegroundColor DarkGray -NoNewline
        $pad = $Cell - ($Key.Length + 3 + $Label.Length)
        if ($pad -gt 0) { Write-Host (' ' * $pad) -NoNewline }
    }

    function Write-KeyValue {
        param([string]$Key,[string]$Value,[string]$Color='Gray')
        Write-Host ('   {0,-26}: ' -f $Key) -ForegroundColor DarkGray -NoNewline
        Write-Host $Value -ForegroundColor $Color
    }

    function Show-FooterPrompt {
        param([string]$Text='Taste zum Zurueck')
        Write-Blank
        Write-Line ("   {0} ..." -f $Text) DarkCyan
        Wait-Key
    }

    function Get-Bar {
        param([int]$Value,[int]$Max,[int]$BarWidth=14)
        if ($Max -le 0) { return ('-' * $BarWidth) }
        $v = [math]::Max(0, [math]::Min($Value, $Max))
        $f = [int][math]::Floor($BarWidth * $v / $Max)
        return ('#' * $f) + ('-' * ($BarWidth - $f))
    }

    # ----------------------------------------------------------------
    # System / Voraussetzungen
    # ----------------------------------------------------------------
    function Get-SystemInfo {
        $isAdmin = $false
        try {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
                       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch {}
        $os = ''
        try { $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption } catch {}
        [pscustomobject]@{
            ComputerName = $env:COMPUTERNAME
            OS           = $os
            IsAdmin      = $isAdmin
        }
    }

    # ----------------------------------------------------------------
    # Zustand (frisch erheben, nie cachen)
    # ----------------------------------------------------------------
    function Get-State {
        # ZUSTAND HIER ERHEBEN - alles read-only, alles defensiv (try/catch)
        [pscustomobject]@{
            Beispiel = 'open'   # open | running | done | failed | warn
        }
    }

    # ----------------------------------------------------------------
    # Aktionen / Ansichten
    # ----------------------------------------------------------------
    function Show-Details {
        param($State)
        Write-Header
        Write-Line '   DETAILS / DIAGNOSE' Yellow
        Write-Blank
        Write-KeyValue 'Beispielwert' $State.Beispiel
        Show-FooterPrompt
    }

    function Show-Help {
        $pages = @(
            @{ Title='Was & Warum'; Lines=@(
                @('Was das Tool prueft/macht - in 1-2 Saetzen.','White'),
                @('',''),
                @('Und was es NICHT tut.','Gray')
            )},
            @{ Title='Bedienung'; Lines=@(
                @('[Enter] Hauptaktion   [D] Details','Gray'),
                @('[H] Hilfe             [B] Beenden','Gray')
            )}
        )
        $index = 0
        while ($true) {
            Write-Header
            $page = $pages[$index]
            Write-Line ("   HILFE   {0}/{1}   -   {2}" -f ($index+1), $pages.Count, $page.Title) Yellow
            Write-Blank
            foreach ($l in $page.Lines) {
                if ($l[0] -eq '') { Write-Blank } else { Write-Line ('   ' + $l[0]) $l[1] }
            }
            Write-Blank
            Write-Rule
            Write-Line '   [->/N] weiter      [<-/P] zurueck      [B] Menue' DarkCyan
            switch (Read-Key) {
                'B'     { return }
                'QUIT'  { return }
                'P'     { if ($index -gt 0) { $index-- } }
                'LEFT'  { if ($index -gt 0) { $index-- } }
                default { if ($index -lt $pages.Count - 1) { $index++ } }
            }
        }
    }

    function Show-Main {
        param($State)
        Write-Header
        Write-StatusRow 'Beispiel-Schritt' $State.Beispiel
        Write-Blank
        Write-Line '   -> Naechster Schritt: ...' Cyan
        Write-Blank
        Write-Rule
        Write-Host '   ' -NoNewline
        Write-MenuCell 'Enter' 'Hauptaktion' 'White'
        Write-MenuCell 'D' 'Details'
        Write-Blank
        Write-Host '   ' -NoNewline
        Write-MenuCell 'H' 'Hilfe'
        Write-MenuCell 'B' 'Beenden'
        Write-Blank
        Write-Blank
    }

    function Invoke-Headless {
        Write-Header
        Write-Line '   Nicht-interaktiver Modus - Einmal-Lauf.' Yellow
        $state = Get-State
        Write-KeyValue 'Beispiel' $state.Beispiel
        # Bei SCHREIBENDEN Tools stattdessen: Meldung + return (keine stillen Aenderungen)
    }

    # ----------------------------------------------------------------
    # Ablauf
    # ----------------------------------------------------------------
    $origCtrlC = $false
    if ($script:Interactive) { try { $origCtrlC = [Console]::TreatControlCAsInput; [Console]::TreatControlCAsInput = $true } catch {} }

    try {
        $script:System = Get-SystemInfo

        Write-Header
        if (-not $script:System.IsAdmin) {
            Write-Line '   [X] Bitte als Administrator starten.' Red
            Show-FooterPrompt 'Taste zum Beenden'; return
        }

        if (-not $script:Interactive) {
            Invoke-Headless
            return
        }

        $quit = $false
        while (-not $quit) {
            $state = Get-State
            Show-Main -State $state
            switch (Read-Key) {
                'ENTER' { <# Hauptaktion; danach Show-FooterPrompt #> }
                'D'     { Show-Details -State $state }
                'H'     { Show-Help }
                'N'     { }
                'B'     { $quit = $true }
                'QUIT'  { $quit = $true }
                default { }
            }
        }

        Write-Header
        Write-Line '   Beendet.' Green
        Write-Blank
    }
    finally {
        if ($script:Interactive) { try { [Console]::TreatControlCAsInput = $origCtrlC } catch {} }
    }
}

Start-ToolName
