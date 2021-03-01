These files are related exclusively to the Windows part of WSL setup.

`wslconfig` is for adjusting parameters like RAM usage. These will be
specific to your environment/computer, so I do not copy these automatically
as I might want to adjust it.

`wsl-whitelist.ps1` is to avoid having Windows Defender spin up and trash
my CPU when doing something in WSL. Honestly, I am not sure if this 
applies to WSL 2, but it was the case in WSL 1.
