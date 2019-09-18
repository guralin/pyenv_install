#!/bin/bash

# dpkgを覗いて、なかったらインストール。
#実行後にdkpgを覗いても、まだ無い場合はインストール失敗とみなして強制終了

# --------------前提パッケージのインストール ----------------------

# 全文一致にするため、パッケージの名前の末尾に:かスペース4つが入っているか確認を行う
function is_installed() {
	local cnt_package=`dpkg -l | grep -E "\s$1(\s{4}|(:))" | wc -l`
    echo $cnt_package
}

# 何らかの原因でinstallが出来ない場合、強制終了させる
function install_package() {
    local is_ins=`is_installed $1`
    if [[ $is_ins -eq 0 ]]; then
        sudo apt -y install $1
        is_ins=`is_installed $1`
        if [[ $is_ins -eq 0 ]]; then
            echo "うまくインストール出来なかったようです。終了します。"
            read
            exit 1
        fi
    fi
}

install_package zlib1g-dev
install_package libssl-dev
install_package libsqlite3-dev
install_package sqlite3
install_package make
install_package gcc

# 対話型インタープリタが使いやすくなる(なくても動く)
install_package libbz2-dev 
install_package libreadline-dev 


# ------------------------------------------------------------------
# --------------python仮想環境の整備 -------------------------------

is_pyenv_path=`cat ~/.profile | grep "export PYENV_ROOT=$HOME/.pyenv" | wc -l`
if [[ -a ~/.pyenv ]]; then
    echo "pyenvはすでに存在します"     #コマンドが存在する時の処理
else
    git clone https://github.com/yyuu/pyenv.git ~/.pyenv

    if [[ $is_pyenv_path -eq 0 ]]; then
        echo '~/.profileにpyenvの設定を書き込みます'
        echo 'export PYENV_ROOT=$HOME/.pyenv' >> ~/.profile
        echo 'export PATH=$PYENV_ROOT/bin:$PATH'>> ~/.profile
        echo 'eval "$(pyenv init -)"'>> ~/.profile
        source ~/.profile
    fi
fi

# pyenvコマンドはここまでで出てくる
is_python366=`pyenv versions | grep " 3.6.6$" | wc -l`
if [[ $is_python366 -eq 0 ]]; then
    echo "pyenvのpython3.6.6をインストールします"
    pyenv install 3.6.6
    is_python366=`pyenv versions | grep " 3.6.6$" | wc -l`
    if [[ $is_python366 -eq 0 ]]; then
        echo "pyenvのpython3.6.6をインストール出来ませんでした。終了します。"
        read
        exit 1
    fi
else
    echo "pyenvのpython3.6.6は既に存在します"
fi

is_virtualenv_path=`cat ~/.profile | grep "eval $(pyenv virtualenv-init -)" | wc -l`
if [[ $is_virtualenv_path -eq 0 ]]; then
    echo '~/.profileにvirtualenvの設定を書き込みます'
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.profile
fi

is_relazy=`pyenv version | grep relazy3.6.6 | wc -l`
if [[ $is_relazy -eq 0 ]]; then
    git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
    pyenv virtualenv 3.6.6 relazy3.6.6
    pyenv local relazy3.6.6
    source ~/.profile
fi
# ------------------------------------------------------------------
# --------------pipモジュールのインストール ------------------------

is_pyenv=`pyenv version | grep "relazy3.6.6" | wc -l`

using_module=`pip freeze`
requirements=`cat requirements.txt`
# 仮想環境がない場合は環境を汚してしまうためインストールを行わない
if [[ $is_pyenv -eq 1 ]]; then
    if [[ $using_module == $requirements ]]; then
        echo "既にモジュールがインストールされています。"
    else
        echo "使用モジュールのインストールを行います"
        pip3 install -r requirements.txt
    fi
else
    echo "仮想環境がうまく作られていないようです。pipモジュールのインストールを行いません"
fi

# -----------終了------------
