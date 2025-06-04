# SFTP Watcher

## Description

Ce dépôt contient un script PowerShell qui surveille un répertoire local et transfère automatiquement les fichiers correspondant à un certain motif (ex. `*.txt`) vers un serveur SFTP.  
L’envoi est déclenché à la création ou à la modification des fichiers. Le fichier source **n’est pas supprimé** après le transfert.

## Fonctionnalités

- Surveillance d’un répertoire local (création et modification de fichiers).
- Transfert automatique de fichiers vers un serveur SFTP distant.
- Temporisation pour laisser les fichiers se stabiliser avant transfert.
- Le transfert repose sur le client **WinSCP**, installé localement.
- Journalisation dans un fichier de log.
- Encapsulation dans un **service Windows** grâce à **WinSW**, avec démarrage automatique.

## Emplacement des fichiers

| Élément                         | Emplacement                                                 |
|---------------------------------|-------------------------------------------------------------|
| Script PowerShell               | `C:\Scripts\watcher-sftp.ps1`                               |
| Répertoire local surveillé      | `C:\Temp\Export` (modifiable dans le script)                |
| Client SFTP (WinSCP)            | `C:\Program Files (x86)\WinSCP\WinSCP.com`                  |
| Fichier de log                  | `C:\Scripts\Logs\watcher-sftp.log`                          |
| Service Windows (WinSW)         | `C:\Services\SFTPWatcher\SFTPWatcherService.exe`            |

## Paramétrage

Tous les paramètres nécessaires sont définis directement dans le script PowerShell (`watcher-sftp.ps1`) :

```powershell
$localPath   = "C:\Temp\Export"           # Répertoire à surveiller
$localFilter = "*.txt"                    # Motif de nom de fichier
$remotePath  = "/autotest"                # Répertoire distant sur le SFTP
$winscpPath  = "C:\Program Files (x86)\WinSCP\WinSCP.com"
$hostname    = "sftp.monhost.com"
$username    = "username"
$password    = "motdepasse"              # À remplacer par une clé SSH si possible
$logFile     = "C:\Scripts\Logs\watcher-sftp.log"
