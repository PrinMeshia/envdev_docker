#!/bin/bash
INSTALL_MAIN_TITLE="Development dockerise"
USER_FRAMEWORK=1
GIT_REPO_URL=""
PROJECT_BDD="project"
PROJECT_DIR="project"
IS_NEW_PROJECT=true
PMA_PORT=8081
MAILDEV_PORT=8082
WWW_PORT=8080
ARCH=""
FRAMEWORK_LIST=( "symfony" "laravel" )

function detectArch() {
  case $(eval "dpkg --print-architecture") in
  armhf)
    ARCH="arm32v7"
    ;;
  arm64 )
    ARCH="arm64v8"
    ;;
  *)
    echo -n "unknown"
    ;;
esac
}
function exitInstall() {
    whiptail \
        --title "$INSTALL_MAIN_TITLE" \
        --msgbox "Install process canceled." 8 45
    exit
}

function frameworkMenu() {
    ADVSEL=$(whiptail --title "$INSTALL_MAIN_TITLE"  --menu "Choose framework to use" 15 60 4 \
        "1" "Symfony" \
        "2" "Laravel"  3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
       USER_FRAMEWORK=$ADVSEL
    else
       exitInstall
    fi
}
function setFolderName()
{
    userdir=$(whiptail --title "$INSTALL_MAIN_TITLE - FOLDER" --inputbox "Enter directory name to use" 10 60 "$PROJECT_DIR" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        if [ ! -z "${userdir}" ]; then
            PROJECT_DIR=$userdir
        fi
    else
        exitInstall
    fi
    userbdd=$(whiptail --title "$INSTALL_MAIN_TITLE - DATABASE" --inputbox "Enter database name to use" 10 60 "$PROJECT_DIR" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        if [ ! -z "${userbdd}" ]; then
            PROJECT_BDD=$userbdd
        else
            PROJECT_BDD=$PROJECT_DIR
        fi
    else
            exitInstall
    fi

}
function setWebPort()
{
    userport=$(whiptail --title "$INSTALL_MAIN_TITLE" --inputbox "Enter phpMyAdmin port" 10 60 "$PMA_PORT" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        if [ ! -z "${userport}" ]; then
            PMA_PORT=$userport
        fi
    else
        exitInstall
    fi
    userport=$(whiptail --title "$INSTALL_MAIN_TITLE" --inputbox "Enter MailDev port" 10 60 "$MAILDEV_PORT" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        if [ ! -z "${userport}" ]; then
            MAILDEV_PORT=$userport
        fi
    else
        exitInstall
    fi
    userport=$(whiptail --title "$INSTALL_MAIN_TITLE" --inputbox "Enter web port" 10 60 "$WWW_PORT" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        if [ ! -z "${userport}" ]; then
            WWW_PORT=$userport
        fi
    else
        exitInstall
    fi
}
function setProjectVars()
{
    url=$(whiptail --title "$INSTALL_MAIN_TITLE" --inputbox "Enter git repository url (Empty if new project)" 10 60  3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        if [ ! -z "${url}" ] ; then
            GIT_REPO_URL=$url
            IS_NEW_PROJECT=false
            basename=$(basename $url)
            filename=${basename%.*}
            PROJECT_DIR=$filename
        fi
    else
        exitInstall
    fi
	setFolderName
	#define web port
	setWebPort
}


function recapBeforeInstall(){
   DISTROS=$(whiptail --title "$INSTALL_MAIN_TITLE" --checklist \
    "installation summary" 15 100 7 \
    "Framework" "${FRAMEWORK_LIST[$USER_FRAMEWORK - 1]}" ON  \
    "Git repository" "$GIT_REPO_URL" ON \
    "Project directory" "$PROJECT_DIR" ON \
    "Project database" "$PROJECT_BDD" ON \
    "PhpMyAdmin port" "$PMA_PORT" ON \
    "Maildev port" "$MAILDEV_PORT" ON \
    "WWW port" "$WWW_PORT" ON 3>&1 1>&2 2>&3)
    
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        startInstall
    else
        exitInstall
    fi
}
function prepareMaildev()
{
	rm -rf maildev
	repository="https://github.com/maildev/maildev.git"
	git clone -q $repository 
	if [ $ARCH = "arm32v7" ]; then
	 	sed -i '/FROM/s/node:/arm32v7\/node:/g' maildev/Dockerfile
	elif [ $ARCH = "arm64v8" ]; then
		sed -i '/FROM/s/node:/arm64v8\/node:/g' maildev/Dockerfile
	fi
}
function editVhost()
{
	cp conf/"${FRAMEWORK_LIST[$USER_FRAMEWORK - 1]}-"vhosts.conf php/vhosts/vhosts.conf
	sed -i "s/PROJECT/${PROJECT_DIR}/g" php/vhosts/vhosts.conf
}
function editDockerCompose()
{
	cp conf/docker-compose.yml docker-compose.yml
	sed -i "s/PMA_PORT/${PMA_PORT}/g" docker-compose.yml
	sed -i "s/MAILDEV_PORT/${MAILDEV_PORT}/g" docker-compose.yml
	sed -i "s/WWW_PORT/${WWW_PORT}/g" docker-compose.yml
}
function initProject() {
    if [ "$IS_NEW_PROJECT" != true ]; then
        git clone -q $GIT_REPO_URL $PROJECT_DIR
    fi
    if [ "$IS_NEW_PROJECT" = true ]; then
        if [ "$USER_FRAMEWORK" = 1 ]; then
            docker exec www_dev_env composer create-project symfony/website-skeleton $PROJECT_DIR 
            sudo chown -R $USER ./ 
        elif [ "$USER_FRAMEWORK" = 2 ]; then
            docker exec www_dev_env composer create-project laravel/laravel $PROJECT_DIR 
            sudo chown -R $USER ./ 
        fi
	else
		docker exec -i  www_dev_env bash -c  "cd $PROJECT_DIR  && composer install "
	fi
    if [ "$USER_FRAMEWORK" = 1 ]; then
            sed -i "/MAILER_DSN=/c\MAILER_DSN=smtp://maildev_dev_env:25" $PROJECT_DIR/.env
            sed -i "/DATABASE_URL=/c\DATABASE_URL=mysql://root:@db_dev_env:3306/${PROJECT_BDD}?serverVersion=mariadb-10.3.27" $PROJECT_DIR/.env
            docker exec -i  www_dev_env bash -c  "cd $PROJECT_DIR  && php bin/console doctrine:database:create"
            if [ "$IS_NEW_PROJECT" != true ]; then
                yes y | docker exec -i  www_dev_env bash -c  "cd $PROJECT_DIR  && php bin/console doctrine:migration:migrate"
            fi
    elif [ "$USER_FRAMEWORK" = 2 ]; then
        docker exec -i  www_dev_env bash -c  "cd $PROJECT_DIR  && php ./artisan sail:install --with=mysql,redis,meilisearch,mailhog,selenium"
    fi
	
}
function startInstall() {
    
    {
        sleep 0.5
        echo -e "XXX\n0\nMaildev configuration... \nXXX"
        prepareMaildev
        echo -e "XXX\n25\nMaildev configuration... Done.\nXXX"
        sleep 0.5

        echo -e "XXX\n25\nVhost Configuration... \nXXX"
        editVhost
        echo -e "XXX\n50\nVhost Configuration... Done.\nXXX"
        sleep 0.5

        echo -e "XXX\n50\nDocker-compose confuguration... \nXXX"
        editDockerCompose
        echo -e "XXX\n75\nDocker-compose confuguration... Done.\nXXX"
        sleep 0.5

        echo -e "XXX\n75\nLaunch Docker... \nXXX"
        docker-compose up -d --quiet-pull
        echo -e "XXX\n100\nLaunch Docker... Done.\nXXX"
        sleep 0.5

            echo -e "XXX\n50\nInit project... \nXXX"
        initProject
        echo -e "XXX\n75\nInit project... Done.\nXXX"
        sleep 1
    } |whiptail --title "$INSTALL_MAIN_TITLE" --gauge "Please wait while installing" 6 60 0
}
start=`date +%s`
#Detect user arch
detectArch

#Start start interface
whiptail \
    --title "$INSTALL_MAIN_TITLE" \
    --msgbox "This utility will allow you to configure your symfony or laravel environment on docker  possibility of starting on an empty project or on an existing one" 8 78

#start process
frameworkMenu
setProjectVars
recapBeforeInstall

end=`date +%s`
whiptail \
    --title "$INSTALL_MAIN_TITLE" \
    --msgbox "installation completed in `expr $end - $start` seconds" 8 78
# echo "$USER_FRAMEWORK"