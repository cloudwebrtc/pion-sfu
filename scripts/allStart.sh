#!/bin/bash

APP_DIR=$(cd `dirname $0`/../; pwd)
cd $APP_DIR
mkdir -p $APP_DIR/logs

help()
{
    echo ""
    echo "start script"
    echo "Usage: ./allRestart.sh [-h]"
    echo ""
}

while getopts "h" arg
do
    case $arg in
        h)
            help;
            exit 0
            ;;
        ?)
            echo "No argument needed. Ignore them all!"
            ;;
    esac
done

# run command
echo "------------etcd--------------"
$APP_DIR/scripts/etcdStart.sh

echo "------------redis--------------"
$APP_DIR/scripts/redisStart.sh

echo "-----------rabbitmq---------------"
$APP_DIR/scripts/mqStart.sh

echo "------------islb--------------"
$APP_DIR/scripts/islbStart.sh

echo "------------ion--------------"
$APP_DIR/scripts/ionStart.sh


echo "------------web--------------"
$APP_DIR/scripts/webStart.sh
echo "--------------------------"



