#!/bin/bash

# Easy parameter check
CMD_NAME=$(basename $0)
if [ $# -ne 1 ]; then
    echo "Usage: ${CMD_NAME} <USER>" 1>&2
    exit 1
fi

# Parameters
USER=$1
GROUP=${USER}

# Directory structures
USER_HOME=/home/${USER}
DOC_ROOT=${USER_HOME}/www
CGI_SCRIPTS=${USER_HOME}/cgi-scripts
LOG_DIR=${USER_HOME}/logs

# Adds a new user and corresponding directories
useradd -m ${USER}
mkdir ${DOC_ROOT} ${CGI_SCRIPTS} ${LOG_DIR}
chown ${USER}:${GROUP} ${DOC_ROOT} ${CGI_SCRIPTS} ${LOG_DIR}

# PHP5 on CGI
touch ${CGI_SCRIPTS}/php.ini
cat << EOT > ${CGI_SCRIPTS}/php5.sh
#!/bin/sh
exec /usr/lib/cgi-bin/php5 -c ${CGI_SCRIPTS}
EOT
chown ${USER}:${GROUP} ${CGI_SCRIPTS}/php5.sh ${CGI_SCRIPTS}/php.ini
chmod u+x ${CGI_SCRIPTS}/php5.sh

# Virtual host config
cat << EOT > /etc/apache2/sites-available/${USER}
<VirtualHost *:80>
    DocumentRoot ${DOC_ROOT}

    SuexecUserGroup ${USER} ${GROUP}
    ScriptAlias /cgi-scripts ${CGI_SCRIPTS}

    LogLevel warn
    ErrorLog ${LOG_DIR}/error.log
    CustomLog ${LOG_DIR}/access.log combined
</VirtualHost>
EOT
a2ensite ${USER}


# Put PHP scripts to verify configs
echo '<?php phpinfo();' > ${DOC_ROOT}/phpinfo.php
echo '<?php echo posix_getpwuid(posix_geteuid())["name"];' > ${DOC_ROOT}/whoami.php
chown ${USER}:${GROUP} ${DOC_ROOT}/phpinfo.php ${DOC_ROOT}/whoami.php
