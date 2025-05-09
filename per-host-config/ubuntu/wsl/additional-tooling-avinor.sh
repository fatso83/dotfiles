download(){
    curl --fail --progress-bar -L -o "$1" "$2"
}

echo "Downloading Pycharm"
download pycharm.tgz 'https://download.jetbrains.com/python/pycharm-2025.1.1.tar.gz?_gl=1*o125dt*_gcl_au*MTA0MDEzODE5OC4xNzQ2Nzc5MTI5*FPAU*MTA0MDEzODE5OC4xNzQ2Nzc5MTI5*_ga*MTYzMjQ1ODMxNy4xNzQ2Nzc5MTI1*_ga_9J976DJZ68*czE3NDY3NzkxMjUkbzEkZzEkdDE3NDY3NzkyNjQkajYwJGwwJGgw'
mkdir -p ~/apps/pycharm
echo "Extracting ..."
tar xf pycharm.tgz -C ~/apps/pycharm
echo "Pycharm extracted"
cd ~/apps

