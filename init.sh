#!/bin/bash
set -- $(locale LC_MESSAGES)
yesptrn="$1"; noptrn="$2"; yesword="$3"; noword="$4"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

GIT_REPO_URL=""
PROJECT_BDD="project"
PROJECT_DIR="project"
IS_NEW_PROJECT=true
PMA_PORT=8081
MAILDEV_PORT=8082
WWW_PORT=8080

prepare_Maildev()
{
	rm -rf maildev
	repository="https://github.com/maildev/maildev.git"
	git clone -q $repository 
	sed -i '/FROM/s/node:/arm32v7\/node:/g' maildev/Dockerfile
}

prepare_symfony_project()
{
	docker exec www_docker_symfony composer create-project symfony/website-skeleton $PROJECT_DIR 
	sudo chown -R $USER ./ 
	
	sed -i "/MAILER_DSN=/c\MAILER_DSN=smtp://maildev_docker_symfony:25" $PROJECT_DIR/.env
	
	sed -i "/DATABASE_URL=/c\DATABASE_URL=mysql://root:@db_docker_symfony:3306/${PROJECT_BDD}?serverVersion=mariadb-10.3.27" $PROJECT_DIR/.env
	docker exec -i  www_docker_symfony bash -c  "cd $PROJECT_DIR  && php bin/console doctrine:database:create"
}
set_folder_name()
{
	read -p "Enter the name of the directory to use (default : $PROJECT_DIR) : " userdir
	if [ ! -z "${userdir}" ]; then
		PROJECT_DIR=$userdir
	fi
	read -p "Enter the database name (default : $PROJECT_DIR) : " userbdd
	if [ -z "${userbdd}" ]; then
		PROJECT_BDD=$PROJECT_DIR
	else
		PROJECT_BDD=$userbdd
	fi
}
set_web_port()
{
	read -p "Enter the port use by phpMyAdmin (default : $PMA_PORT) : " userport
	if [ ! -z "${userport}" ]; then
		PMA_PORT=$userport
	fi

	read -p "Enter the port use by MailDev (default : $MAILDEV_PORT) : " userport
	if [ ! -z "${userport}" ]; then
		MAILDEV_PORT=$userport
	fi

	read -p "Enter the port use by web (default : $WWW_PORT) : " userport
	if [ ! -z "${userport}" ]; then
		WWW_PORT=$userport
	fi
}
set_project_var()
{
	read -p "Enter git repository url (Empty if new project) : " url
	if [ ! -z "${url}" ] ; then
		IS_NEW_PROJECT=false
		basename=$(basename $url)
		filename=${basename%.*}
		while true; do
				read -p "Use $filename as folder name (${yesword} / ${noword})? " yn
				case $yn in
					${yesptrn##^} ) PROJECT_DIR=$filename ; break ;;
					${noptrn##^} )  set_folder_name break ;;
					* ) printf "Wrong response : (${yesword} / ${noword}) .";;
				esac
		done
	else
		printf "No git repository\n"
		printf "Create empty project\n"
		set_folder_name
	fi

	#defin web port
	set_web_port
}
edit_vhost()
{
	cp conf/vhosts.conf php/vhosts/vhosts.conf
	sed -i "s/PROJECT/${PROJECT_DIR}/g" php/vhosts/vhosts.conf
}
edit_docker_compose()
{
	cp conf/docker-compose.yml docker-compose.yml
	sed -i "s/PMA_PORT/${PMA_PORT}/g" docker-compose.yml
	sed -i "s/MAILDEV_PORT/${MAILDEV_PORT}/g" docker-compose.yml
	sed -i "s/WWW_PORT/${WWW_PORT}/g" docker-compose.yml
}
#Define all variable
printf  "PREPARE PROJECT VAR\n"
set_project_var

printf  "PREPARE PROJECT MAILDEV"
prepare_Maildev
printf  " >>> ${GREEN}DONE${NC}\n"

printf  "CONFIGURE VHOSTS"
edit_vhost
printf " >>> ${GREEN}DONE${NC}\n"


if [ ! $IS_NEW_PROJECT ] ; then
	printf  "GET SOURCE PROJECT"
	git clone -q $GIT_REPO_URL $PROJECT_DIR
	printf  " >>> ${GREEN}DONE${NC}\n"
fi

printf  "CONFIGURE DOCKER_COMPOSE"
edit_docker_compose
printf  " >>> ${GREEN}DONE${NC}\n"

printf  "LAUNCH DOCKER\n"
docker-compose up -d --quiet-pull
printf  " >>> ${GREEN}DONE${NC}\n"

if [ $IS_NEW_PROJECT ] ; then
	printf  "INIT SYMFONT PROJECT\n"
	prepare_symfony_project
	printf  "${GREEN}DONE${NC}\n"
fi


