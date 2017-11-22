#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

# This script setup environment for WSO2 product deployment
readonly USERNAME=$2
readonly WUM_USER=$4
readonly WUM_PASS=$6
readonly JDK=$8
readonly DB_ENGINE=$10
readonly LIB_DIR=/home/${USERNAME}/lib

install_packages() {
    apt-get update -y
    apt install git -y
}

setup_java_env() {
    if [ "$JDK" = "JDK7" ]; then
        JAVA_HOME=${JDK7}
    elif [ "$JDK" = "JDK8" ]; then
        JAVA_HOME=${JDK8}
    fi

    JAVA_HOME_FOUND=$(grep -r "JAVA_HOME=" /etc/environment | wc -l  )
    echo ">> Setting up JAVA_HOME ..."
    if [ ${JAVA_HOME_FOUND} = 0 ]; then
        echo ">> Adding JAVA_HOME entry."
        echo JAVA_HOME=${JAVA_HOME} >> /etc/environment
    else
        echo ">> Updating JAVA_HOME entry."
        sed -i "/JAVA_HOME=/c\JAVA_HOME=${JAVA_HOME}" /etc/environment
    fi
    source /etc/environment

    echo ">> Setting java userPrefs ..."
    mkdir -p /tmp/.java/.systemPrefs
    mkdir /tmp/.java/.userPrefs
    sudo -u ${USERNAME} chmod -R 755 /tmp/.java
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
    echo "export JAVA_OPTS='-Djava.util.prefs.systemRoot=/tmp/.java/ -Djava.util.prefs.userRoot=/tmp/.java/.userPrefs'" >> /etc/profile
    source /etc/profile
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
    wget -O ${LIB_DIR}/jdbc-connector.jar http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.44/mysql-connector-java-5.1.44.jar
}

get_postgre_jdbc_driver() {
    wget -O ${LIB_DIR}/jdbc-connector.jar https://jdbc.postgresql.org/download/postgresql-42.1.4.jar
}

main() {

    mkdir -p ${LIB_DIR}

    install_packages
    setup_java_env
    install_wum
    if [ $DB_ENGINE = "postgres" ]; then
        get_postgre_jdbc_driver
    elif [ $DB_ENGINE = "mysql" ]; then
        get_mysql_jdbc_driver
    fi

    echo "Done!"
}

main
