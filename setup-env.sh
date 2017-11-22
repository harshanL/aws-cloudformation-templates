#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

# This script setup environment for WSO2 product deployment
readonly USERNAME=$2
readonly WUM_USER=$4
readonly WUM_PASS=$6
readonly JDK=$8
readonly LIB_DIR=/home/${USERNAME}/lib

install_packages() {
    apt-get update -y
    apt install git -y
}

setup_java_home() {
    source /home/ubuntu/.bashrc
    export JAVA_HOME=${JDK}
    source /home/ubuntu/.bashrc
    echo $JAVA_HOME > /home/ubuntu/java.txt
}

install_wum() {

    echo "127.0.0.1 $(hostname)" >> /etc/hosts
    wget -P ${LIB_DIR} https://product-dist.wso2.com/downloads/wum/1.0.0/wum-1.0-linux-x64.tar.gz
    cd /usr/local/
    tar -zxvf "${LIB_DIR}/wum-1.0-linux-x64.tar.gz"
    chown -R ${USERNAME} wum/
    
    local is_path_set=$(grep -r "usr/local/wum/bin" /etc/profile | wc -l  )
    echo ">> Adding WUM installation directory to PATH ..."
    if [ ${is_path_set} = 0 ]; then
        echo ">> Adding WUM installation directory to PATH variable"
        echo "export PATH=\$PATH:/usr/local/wum/bin" >> /etc/profile
    fi
    source /etc/profile
    echo ">> Initializing WUM ..."
    sudo -u ${USERNAME} /usr/local/wum/bin/wum init -u ${WUM_USER} -p ${WUM_PASS}
}

get_mysql_jdbc_driver() {
    wget -P ${LIB_DIR} http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.44/mysql-connector-java-5.1.44.jar
}

main() {

    mkdir -p ${LIB_DIR}

    install_packages
    setup_java_home
    install_wum
    get_mysql_jdbc_driver

    echo "Done!"
}

main
