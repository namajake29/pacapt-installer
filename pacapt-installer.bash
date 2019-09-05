#!/usr/bin/env bash
set -eu

## pacapt installer for Ubuntu

## Initial function
function red_log () {
    echo -e "\033[0;31m$@\033[0;39m"
    return 0
}

function search_pkg () {
    package_exist=$(dpkg --get-selections  | grep -w $1 | awk '{print $1}')
    if [[ -n $package_exist ]]; then
        return 0
    else
        return 1
    fi
}

## Check root.
if [[ ! $UID = 0 ]]; then
    red_log "You need root permission."
    exit 1
fi

## Initialize
mode=0
argument=$1

## Settings
working_directly="./pacapt"
control_url="https://raw.githubusercontent.com/Hayao0819/pacapt-installer/master/control"
postinst_url="https://raw.githubusercontent.com/Hayao0819/pacapt-installer/master/postinst"
postrm_url="https://raw.githubusercontent.com/Hayao0819/pacapt-installer/master/postrm"
pacapt_url="https://github.com/icy/pacapt/raw/ng/pacapt"
pacapt_path="usr/local/bin/pacapt"
initial_directory=$(pwd)


## Select mode.
if [[ -z argument ]]; then
    echo 
    echo "------pacapt installer------"
    echo
    echo "How do you install pacapt?"
    echo "1: Place pacapt directly. (Do not use Package Manager.)"
    echo "2: After creating the deb file, install it automatically."
    echo "3: After creating the deb file, install it yourself."
    printf "Please enter mode number.: "
    read mode
else
    mode=$1
fi

## functions 
function check_debian () {
    ## Check dist
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case $ID in 
            ubuntu ) echo "The distribution is Ubuntu." ;;
            debian ) echo "The distribution is Debian." ;;
            * ) red_log "This mode is only available for Debian and its derivatives."
                exit 1 ;;
        esac
    fi
    return 0
}
function make_link () {
    sudo ln -s /$pacapt_path/usr/local/bin/pacapt-tlmgr
    sudo ln -s /$pacapt_path /usr/local/bin/pacapt-conda
    sudo ln -s /$pacapt_path /usr/local/bin/p-tlmgr
    sudo ln -s /$pacapt_path /usr/local/bin/p-conda
    sudo ln -sv /$pacapt_path /usr/local/bin/pacman || true
    return 0
}

function pacapt_to_yay () {
    echo "alias yay='sudo pacapt'" >> /etc/bash.bashrc
    echo "alias yay='sudo pacapt'" >> /etc/skel/.bashrc
    source /etc/bash.bashrc
    return 0
}

function mode1 () {
    red_log "Downloading pacapt."
    sudo wget  -O /$pacapt_path $pacapt_url
    sudo chmod 755 /$pacapt_path
    make_link
    # pacapt_to_yay
    return 0
}

function build_deb () {
    red_log "Start creating a Debian package file."
    if [[ ! -d $working_directly ]]; then 
        echo "Creating working directory."
        mkdir $working_directly
    fi
    cd $working_directly
    red_log "Creating working directory."
    mkdir -p ./$( echo $pacapt_path | sed -e 's/pacapt//g')
    red_log "Downloading pacapt."
    sudo wget -O ./$pacapt_path $pacapt_url
    red_log "Creating DEBIAN directory."
    mkdir DEBIAN
    cd ./DEBIAN
    red_log "Downloading control."
    wget $control_url
    red_log "Downloading postinst"
    wget $postinst_url
    red_log "Downloading postrm"
    wget $postrm_url
    echo -e "$(md5sum ../$pacapt_path | awk '{print $1}')    $pacapt_path" > ./md5sums
    cd ../../
    chmod -R 755 $working_directly
    dpkg -b $working_directly
    return 0
}

function mode2 {
    check_debian
    build_deb
    if [[ $(search_pkg gdebi) = 1 ]]; then
        red_log "Installing gdebi..."
        apt-get --yes update > /dev/null
        apt-get --yes install gdebi-core > /dev/null
    fi
    gdebi $working_directly.deb
    if [[ $(search_pkg gdebi) = 1 ]]; then
        red_log "Uninstalling gdebi..."
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
    check_debian
    build_deb
    rm -r $working_directly
    exit 0
}
function error {
    red_log "Enter the mode number."
    exit 1
}


## run function
case $mode in
    1 ) mode1 ;;
    2 ) mode2 ;;
    3 ) mode3 ;;
    0 ) error ;;
    * ) error ;;
esac

cd $initial_directory