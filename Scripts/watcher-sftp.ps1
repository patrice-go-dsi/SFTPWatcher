####################################################################################
# Surveille le dossier localPath. Si un fichier correspondant au filtre localFilter 
# est copié ou modifié (d'ou le 2 évènements qui sont créés), celà déclenche une 
# connexion SFTP vers hostname et copie le fichier qui a matché.
# 
# Pour lancer le script automatiquement, il faut le placer dans un service Windows.
# Voir  https://github.com/winsw/winsw
####################################################################################

####################################################################################
# Paramètres
####################################################################################
$localPath = "C:\Temp\Export"  # Dossier qui sera surveillé
$localFilter = "*.txt"  # Filtre pour les fichiers à surveiller (création et modification)
$remotePath = "/autotest"  # Pas besoin de / à la fin
$winscpPath = "C:\Program Files (x86)\WinSCP\WinSCP.com"
$hostname = "sftp.monhost.com"
$username = "username"
$password = "motdepasse" # Préfère clé SSH si possible
$logFile = "C:\Scripts\Logs\watcher-sftp.log"
####################################################################################

####################################################################################
# === FONCTION DE LOGGING ===
####################################################################################
function Global:WriteLog() {
	param($message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
    Write-Host "$timestamp - $message"
}

####################################################################################
# === Fonction d'envoi SFTP ===
####################################################################################
function Global:SendToSFTP() {
	param($filePath)
    WriteLog -message "Tentative d'envoi du fichier : $filePath"

	$fileName = [System.IO.Path]::GetFileName($filePath)

    # Échappe les espaces et caractères spéciaux
    $escapedFile = $filePath -replace '\\', '\\\\'

    $script = @"
option batch abort
option confirm off
open sftp://${username}:$password@$hostname -hostkey=*
option transfer binary
put `"${escapedFile}`" `"${remotePath}/${fileName}`"
exit
"@

	# $script | Out-File -FilePath "C:\Temp\Export\script_winscp.test"
    $scriptFile = "$env:TEMP\winscp_script.txt"
    $script | Set-Content -Encoding Ascii $scriptFile

    # Appel WinSCP sans parasite
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $winscpPath
    $processInfo.Arguments = "/script=`"$scriptFile`""
    $processInfo.RedirectStandardOutput = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $output = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    Remove-Item $scriptFile -Force

    if ($process.ExitCode -eq 0) {
        WriteLog -message "✅ Fichier transféré : $fileName"
    } else {
        WriteLog -message "❌ Erreur lors du transfert de $fileName : $output"
    }
}

####################################################################################
# === Initialisation du watcher ===
####################################################################################
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $localPath
$watcher.IncludeSubdirectories = $false
$watcher.Filter = $localFilter
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'

####################################################################################
# === Abonnement aux événements ===
####################################################################################
Register-ObjectEvent $watcher Created -Action {
    Start-Sleep -Seconds 2  # Laisse le temps d'écriture du fichier
	WriteLog -message "Création de fichier détectée : $($Event.SourceEventArgs.FullPath)"
	$path = $Event.SourceEventArgs.FullPath
    SendToSFTP -filePath $path
} | Out-Null

Register-ObjectEvent $watcher Changed -Action {
    Start-Sleep -Seconds 2
	WriteLog -message "Modification de fichier détectée : $($Event.SourceEventArgs.FullPath)"
	$path = $Event.SourceEventArgs.FullPath
    SendToSFTP -filePath $path
} | Out-Null

Get-EventSubscriber | Format-Table SubscriptionId, SourceIdentifier, EventName, State

try {
    WriteLog -message "🎯 Surveillance en cours... CTRL+C pour quitter."
    while ($true) {
        Start-Sleep -Seconds 10
    }
} finally {
    Get-EventSubscriber | Unregister-Event -Force
    WriteLog -message "🧹 Nettoyage des watchers effectué."
}

####################################################################################
# EOF
####################################################################################