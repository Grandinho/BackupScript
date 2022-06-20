<#
Titel: Team NNM Backup Projekt 
Datum: 17.06.2022
Autoren: Noah, Nael, Mateusz
File-Name: PAA_Backup
Version: 1.0.0.5

Variablen:

$TopSrc_p: Quellpfad des Backup
$TopBck_p: Zielpfad des Backup

$LogPath_p: Pfad, in dem der Logdatei gespeichert wird
$time: Aktuelles Zeit (wird für den Namen der Logdatei verwendet)
$PathExists: Variable zum Überprüfen von Quellpfad
$date: Aktuelles Datum (wird für den Namen der Logordner verwendet)

$file_path: Pfad der einzelnen Dateien, welche sich in TopSrc befinden 
$target_path: Variable zur speicherung des relativen Pfad
$_: Mit dieser Variable greifen wir in einer Schleife auf das aktuelle Objekt (in unserem Fall ein Ordner oder eine Datei) zu

$FileCheckSrc: Variable zur Überprüfung, ob der Inhalt der Quelldatei mit der Datei im Backup übereinstimmt
$FileCheckBck: Variable zur Überprüfung, ob der Inhalt der Quelldatei mit der Datei im Backup übereinstimmt
$Filesdifferncecount: Anzahl fehlerhafter Dateien
#>


function Create-Backup
{
param (
[string]$TopSrc_p, #Quellpfad
[string]$TopBck_p,  #Zielpfad
[string]$LogPath_p #Logpfad
)

$date = Get-Date -Format "dd/MM/yyyy" #Variable mit dem aktuellen Datum wird initialisert und deklariert
$time = Get-Date -Format "HH-mm-ss" #Variable mit dem aktuellen Zeit wird initialisert und deklariert

#Erweiterung des Log-Backup-Pfades um eine Ordnerstruktur zu erstellen und ein Überschreiben der Datei zu vermeiden
$LogPath_p += "\$date\Log_$time.txt" 
$TopBck_p += "\Backupdate_$date\Backuptime_$time"

Start-Transcript -Path $LogPath_p #Logging wird gestartet

$PathExists = Test-Path -Path $TopSrc_p
if (-not $PathExists) 
{ 
    Write-Host "Der Pfad, den Sie eingegeben haben existiert nicht";
    break;
}

Get-ChildItem $TopSrc_p -Recurse -Directory  | Copy-Item -Destination {$_.FullName.Replace($TopSrc_p, $TopBck_p)}  -Force #Alle Ordner aus TopSrc werden nach TopBck kopier

#Eine Schleife wird erstellt, welche durch alle Dateien geht, die sich im TopSrc Pfad befinden
Get-ChildItem $TopSrc_p -Recurse -file  | Select-Object | ForEach-Object {  
    [string]$file_path = $_.FullName #Der absolute Pfad der Dateien wird in einer Variable gespeichert
    $target_path = $TopBck_p + $file_path.Remove(0,$TopSrc_p.Length) #Anhand des absoluten Pfads wird der relative Pfad erstellt
    Copy-Item $file_path -Destination  $target_path -Force #Die Dateien werden vom Quellordner in den Zielordner kopiert
#Write-Host für die Loggin Datei
    Write-Host "**********************************************************************************" 
    Write-host "$_ mit Pfad ($file_path) wurde in den Backupordner unter dem Pfad $target_path kopiert"

}


Write-Host 
"---------------------------------------------------------`n 
Prüfung, ob alle Dateien korrekt kopiert wurden
`n---------------------------------------------------------"

#Überprüfung, ob der Inhalt der kopierten Datei mit der Quelldatei übereinstimmt
Get-ChildItem $TopSrc_p -Recurse -file   | Select-Object | ForEach-Object {

    $FileCheckSrc = $_.FullName 
    $FileCheckBck = $TopBck_p + $FileCheckSrc.Remove(0,$TopSrc_p.Length)
    $Filesdifferencecount = 0

    if ((Get-FileHash $FileCheckSrc).hash -ne (Get-FileHash $FileCheckBck).hash)
    {
        $Filesdifferencecount++
    }

}

if ($Filesdifferencecount -eq 0) 
{
    Write-Host "Alle Dateien wurden korrekt kopiert!" -ForegroundColor Green
}
else
{
Write-Host "Nicht alle Datein wurden korrekt kopiert. Anzahl, nicht kopierter Files: $Filesdifferencecount"
}

Stop-Transcript
}