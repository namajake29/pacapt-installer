#!/usr/bin/env bash

## pacapt installer for Ubuntu


## Check root.
if [[ ! $UID = 0 ]]; then
    echo "You need root permission."
    exit 1
fi

## Initialize
mode=0
alias wget='wget -q'
gdebi=$(dpkg --get-selections  | grep "gdebi" | awk '{print $1}')


## Settings
working_directly="./pacapt"
control_url="https://raw.githubusercontent.com/Hayao0819/pacapt-installer/master/control"
postinst_url="https://raw.githubusercontent.com/Hayao0819/pacapt-installer/master/postinst"
pacapt_url="https://github.com/icy/pacapt/raw/ng/pacapt"
pacapt_path="usr/local/bin/pacapt"
initial_directory=$(pwd)


## Select mode.
echo 
echo "------pacapt installer------"
echo
echo "How do you install pacapt?"
echo "1: Place pacapt directly. (Do not use Package Manager.)"
echo "2: After creating the deb file, install it automatically."
echo "3: After creating the deb file, install it yourself."
printf "Please enter mode number.: "
read mode

function make_link {
    sudo ln -s /$pacapt_path/usr/local/bin/pacapt-tlmgr
    sudo ln -s /$pacapt_path /usr/local/bin/pacapt-conda
    sudo ln -s /$pacapt_path /usr/local/bin/p-tlmgr
    sudo ln -s /$pacapt_path /usr/local/bin/p-conda
    sudo ln -sv /$pacapt_path /usr/local/bin/pacman || true
    return 0
}

function pacapt_to_yay {
    echo "alias yay='sudo pacapt'" >> /etc/bash.bashrc
    echo "alias yay='sudo pacapt'" >> /etc/skel/.bashrc
    source /etc/bash.bashrc
    return 0
}

function mode1 {
    sudo wget -q -O /$pacapt_path $pacapt_url
    sudo chmod 755 /$pacapt_path
    make_link
    pacapt_to_yay
    return 0
}

function build_deb {
    if [[ ! -d $working_directly ]]; then 
        mkdir $working_directly
    fi
    cd $working_directly
    mkdir -p ./usr/local/bin/
    sudo wget -O ./$pacapt_path $pacapt_url
    mkdir DEBIAN
    cd ./DEBIAN
    wget $control_url
    wget $postinst_url
    echo -e "$(md5sum ../$pacapt_path | awk '{print $1}')    $pacapt_path" > ./md5sums
    cd ..
    cd ..
    chmod -R 755 $working_directly
    dpkg -b $working_directly
    return 0
}

function mode2 {
    build_deb
    if [[ -z $gdebi ]]; then
        echo "Installing gdebi..."
        apt-get --yes update > /dev/null
        apt-get --yes install gdebi-core > /dev/null
    fi
    gdebi $working_directly.deb
    if [[ -z $gdebi ]]; then
        echo "Uninstalling gdebi..."
        apt-get --yes purge gdebi-core > /dev/null
        apt-get --yes --purge autoremove > /dev/null
        apt-get --yes clean > /dev/null
    fi
    rm -r $working_directly
    rm $working_directly.deb
    pacapt_to_yay
    # pacapt -V
    return 0
}

function mode3 {
    build_deb
    rm -r $working_directly
    exit 0
}
function error {
    echo "Enter the mode number."
    exit 1
}

case $mode in
    1 ) mode1 ;;
    2 ) mode2 ;;
    3 ) mode3 ;;
    0 ) error ;;
    * ) error ;;
esac

cd $initial_directory
unalias wget