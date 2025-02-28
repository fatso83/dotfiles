#iex (new-object net.webclient).downloadstring('https://get.scoop.sh')

# This must be run as Administrator
# https://dev.to/d4vsanchez/use-1password-ssh-agent-in-wsl-2j6m
if (! (Test-Path -Path "./npiperelay") ) {
    Invoke-WebRequest https://github.com/jstarks/npiperelay/releases/download/v0.1.0/npiperelay_windows_amd64.zip -OutFile npiperelay.zip
    Expand-Archive npiperelay.zip 
    copy ./npiperelay/npiperelay.exe C:/Windows/
}
