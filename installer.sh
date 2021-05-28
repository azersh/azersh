#!/bin/bash
# installer.sh

# VARS
PYTHON_SYS_BIN='/usr/bin/python3'
TARGET_PATH='/usr/local/cmdb'
PYTHON_VENV_BIN="$TARGET_PATH/bin/python"
REPO_PATH="$HOME/Documents/conecta-config/SESDR"


info()
{
	echo "INFO: ${@}" 1>&2
} # end info


die()
{
	echo "FATAL: ${@}" 1>&2
	exit 1
} # end die


checkroot()
{
    # am i root?
    if [ "$EUID" -eq 0 ]
    then 
        die "This installer needs to run as your user and will prompt you for sudo password. Use ./installer.sh"
    fi
} # end checkrun


prechecks()
{
    info "Insert sudo password when requested"
    # CHECK OLD INSTALLATION
    if [ -d $TARGET_PATH ]
    then 
        echo "CMDB Found! Removing current release"
        sudo rm -Rf $TARGET_PATH || die "Unable to remove old cmdb"
    fi

    # CHECK REQUIREMENTS

    # check python
    ls -l $PYTHON_SYS_BIN &>/dev/null || die "Can't find python interpreter, please check your python3 location and edit the variable PYTHON_SYS_BIN"

    # check virtual env
    virtualenv --version &>/dev/null
    if [ $? -eq 0 ]
    then
        info ALL GOOD: virtualenv OK
    else
        echo CHECK: pip
        pip3 -V &>/dev/null
        if [ $? -eq 0 ]
        then
            info "INSTALLING: virtualenv"
            sudo $PYTHON_SYS_BIN -m pip install virtualenv || die "virtualenv installation failed"
        else
            info "Assuming you are on Ubuntu"
            info "INSTALLING: python3-pip and python3-venv"
            sudo apt install -y python3-pip python3-venv || die "python3-pip python3-venv installation failed"
            #info "INSTALLING: virtualenv"
            #sudo $PYTHON_SYS_BIN -m pip install virtualenv || die "virtualenv installation failed"
        fi
    fi

} # end prechecks

install()
{
    # CREATE VIRTUAL ENV
    sudo $PYTHON_SYS_BIN -m venv $TARGET_PATH requirements || die "creation of virtual env failed"

    # INSTALLING
    sudo cp -r ./* $TARGET_PATH || die "copy cmdb to $TARGET_PATH failed"
    sudo chmod 755 $TARGET_PATH/* || die "chmod cmdb on $TARGET_PATH failed"
    sudo -H $PYTHON_VENV_BIN -m pip install --upgrade pip wheel || die "pip wheel installation failed"
    sudo -H $PYTHON_VENV_BIN -m pip install -r $TARGET_PATH/requirements.txt || die "requirements installation failed"
    info "ALL GOOD: virtualenv successfully created"
    echo ""
    info "this is the cmdb default command:"
    echo $PYTHON_VENV_BIN $TARGET_PATH/main.py
    echo ""
    echo "you can make an alias of it, please read the documentation: https://github.ibm.com/UNIXBO/cmdb/tree/master#installation"


    # CHECK REPOSITORY PATH
    if test -d $REPO_PATH
    then
        info "ALL GOOD: Folder $REPO_PATH exists"
        if [[ `ls -l $REPO_PATH/BLU\ SERVER\ SESDR\ Extract\ *.xlsm | wc -l` -ge 1 ]]
        then
            info "ALL GOOD: SESDR FILE OK"
            SESDR=OK
        else
            info "WARNING: SESDR FILE MISSING in $REPO_PATH"
        fi
        if [[ `ls -l $REPO_PATH/File\ Customer\ *.xls | wc -l` -ge 1 ]]
        then
            info "ALL GOOD: FILE CUSTOMER OK"
            CUST=OK
        else
            info "WARNING: FILE CUSTOMER MISSING in $REPO_PATH"
        fi

        if [ "$SESDR" == 'OK' ] && [ "$CUST" == 'OK' ]
        then
            info "ALL GOOD: Updating cmdb csv"
            /usr/local/cmdb/bin/python /usr/local/cmdb/update_cmdb_sesdr_customer.py
        else
            info "WARNING: Can't update cmdb"
        fi
    else
        mkdir -p $REPO_PATH
        info "WARNING: Folder created. Please put SESDR and FILE CUSTOMER in $REPO_PATH"
    fi

} # end install


# MAINCYCLE
#
checkroot
#
prechecks
#
install
#
info "installation completed"