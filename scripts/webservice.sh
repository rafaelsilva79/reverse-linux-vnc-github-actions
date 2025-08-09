#!/bin/bash

if [ "$RUNNER_WEBSERVICE" == "novnc" ]
then
    # Setup noVNC
    sudo apt-get install novnc websockify
    websockify -D \
        --web /usr/share/novnc/ \
        8080 \
        localhost:7582

elif [ "$RUNNER_WEBSERVICE" == "cloud9" ]
then
    # Setup cloud9
    cd ~
    mkdir workspace
	# Python 2.7
    mkdir python2
    cd python2
    sudo apt-get install libssl-dev
    wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
    tar xzf Python-2.7.18.tgz
    cd Python-2.7.18
    sudo ./configure --enable-optimizations
    sudo make altinstall
    sudo ln -s /usr/local/bin/python2.7 /usr/bin/python2
    sudo rm /usr/bin/python
    sudo ln -s /usr/local/bin/python2.7 /usr/bin/python
    cd ..
    wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
    python2 get-pip.py
    pip2 install requests==2.12.4
    cd ~
	# Node.js 6
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 6
    nvm use 6
    nvm alias default 6
	# Cloud9
    git clone https://github.com/c9/core.git c9sdk
    cd c9sdk
    sudo apt-get install tmux
    echo 'if [ -f ~/.bashrc ]; then source ~/.bashrc; fi' >> ~/.bash_profile
    wget https://raw.githubusercontent.com/c9/install/refs/heads/master/link.sh -O scripts/link.sh
    chmod +x scripts/link.sh
    ./scripts/link.sh
    npm install
    node ./server.js -p 8080 -l 0.0.0.0 -a linux:$VNC_PASSWORD -w ../workspace &

elif [ "$RUNNER_WEBSERVICE" == "vscode" ]
then
    # Setup code-server (vscode)
    cd ~
    mkdir workspace
    curl -fsSL https://code-server.dev/install.sh | sh
    sudo systemctl start code-server@$USER
    sudo systemctl enable --now code-server@$USER
    sleep 5
    cat /home/runner/.config/code-server/config.yaml
fi

exit
