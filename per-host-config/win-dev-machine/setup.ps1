Write-Output "Run this as Administrator"
iex (new-object net.webclient).downloadstring('https://get.scoop.sh')

# https://dev.to/d4vsanchez/use-1password-ssh-agent-in-wsl-2j6m
Invoke-WebRequest https://github.com/jstarks/npiperelay/releases/download/v0.1.0/npiperelay_windows_amd64.zip -OutFile npiperelay.zip
Expand-Archive npiperelay.zip 
copy npipelay/npiperelay.exe C:/Windows/
