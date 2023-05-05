#!/bin/bash
cd /opt/tpautotest/test_TP/

green='\033[0;32m'
clear='\033[0m'
red='\033[0;31m'

function printfunction {
if [ "$(sudo docker container inspect -f '{{.State.Running}}' $name )" == "true" ]; then
        id=$(sudo docker ps -aqf "name=$name")
        printf  "${green}$name container is up and running${clear}-$id"
        echo
else
        echo "Error $name startup is fail"
        exit 1
fi
}

printf "${red}This script will stop and remove all docker container${clear}\n"
sudo docker stop $(sudo docker ps -a -q) &>/dev/null
echo "Containers stopped"
sudo docker rm $(sudo docker ps -a -q) &>/dev/null
echo "Containers removed"

sudo docker run -d --name selenoid -p 7779:4444 -v /var/run/docker.sock:/var/run/docker.sock -v /opt/tpautotest/test_TP/selenoid/:/etc/selenoid/:ro aerokube/selenoid:latest-release &>/dev/null
name='selenoid'
printfunction

sudo docker run -d --name selenoid-ui -p 8080:8080 aerokube/selenoid-ui --selenoid-uri ---IP---:7779 &>/dev/null ###IP replace     
name='selenoid-ui'
printfunction

sudo docker run -d -p 7778:5050 --name allure -e CHECK_RESULTS_EVERY_SECONDS=NONE -e KEEP_HISTORY="TRUE" -e SECURITY_USER="test" -e SECURITY_PASS="testpass" -e SECURITY_ENABLED=1 -v ${PWD}/allure-results:/app/allure-results -v ${PWD}/allure-reports:/app/default-reports allure-docker-service:latest &>/dev/null
name='allure'
printfunction

sudo docker run -d -p 7776:5252 --name allure-ui -e ALLURE_DOCKER_PUBLIC_API_URL= ---IP---:7778 frankescobar/allure-docker-service-ui &>/dev/null  ###IP replace     
name='allure-ui'
printfunction

sudo docker run -d -p 7777:6060 -p 50000:50000 --name jenkins -v /opt/tpautotest/test_TP/jenkins_home/_data/:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --env JENKINS_OPTS=--httpPort=6060 trading-platform-jenkins:0.0.1 &>/dev/null
name='jenkins'
printfunction
while [ "$curl" != "403" ]
do
        sleep 2s
        curl=$(curl --silent --head ---IP--- | awk '/^HTTP/{print $2}') ###IP replace                                       
echo "Waiting for jenkins"
done
echo "Jenkins->---IP---:7777/ " ###IP replace     
while [ "$curl" != "200" ]
do
        sleep 2s
        curl=$(curl --silent --head ---IP---:7776 | awk '/^HTTP/{print $2}') ###IP replace     
echo "Waiting for allure"
done
echo "Allure-ui-> ---IP---:7776/ " ###IP replace     

