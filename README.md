# LazyScripts

This is a set of bash shell functions to simplify and automate specific routine tasks, as well as some more specialized ones.

## Compatibility
* RedHat Enterprise Linux 5+
* CentOS 5+
* Ubuntu 10.04+

## Installation
Run this bash function as root:

```bash
function lsgethelper() {
        local LZDIR=/root/.lazyscripts/tools;
        if [ -d ${LZDIR} ]; then
                cd ${LZDIR} \
                && git reset --hard HEAD \
                && git clean -f	\
                && git pull git://github.com/hhoover/lazyscripts.git master; \
        else
                cd \
                && git clone git://github.com/hhoover/lazyscripts.git ${LZDIR};
        fi
        cd;
        source ${LZDIR}/ls-init.sh;
}
lsgethelper && lslogin
```
Throw this in your .bashrc for extra credit.
## Functions
| **Function** | **Description** |
|:-------------|:----------------|
|lsapcheck|Verify apache max client settings and memory usage.|
|lsapdocs|Prints out Apache's DocumentRoots|
|lsapproc|Shows the memory used by each Apache process|
|lsbigfiles|List the top 50 files based on disk usage.|
|lsbwprompt|Switch to a plain prompt.|
|lscloudkick|Installs the Cloudkick agent|
|lscolorprompt|Switch to a fancy colorized prompt.|
|lsconcurchk |Show concurrent connections|
|lscrtchk|Check SSL Cert/Key to make sure they match|
|lsdrupal|Install Drupal 7 on this server|
|lshaproxy|Install HAProxy on this server|
|lshighio|Reports stats on processes in an uninterruptable sleep state.|
|lshppool|Adds a new pool to an existing HAProxy config|
|lsinfo|Display useful system information|
|lslsync|Install lsyncd and configure this server as a master|
|lsmycopy|Copies an existing database to a new database.|
|lsmycreate|Creates a MySQL DB and MySQL user|
|lsmyengines|List MySQL tables and their storage engine.|
|lsmylogin|Auto login to MySQL|
|lsmytuner|MySQL Tuner.|
|lsmyusers|List MySQL users and grants.|
|lsnginx|Replace Apache with nginx/php-fpm|
|lsnodejs|Installs Node.js and Node Package Manager|
|lsparsar|Pretty sar output|
|lspma|Installs phpMyAdmin|
|lspostfix|Set up Postfix for relaying email|
|lsrblcheck|Server Email Blacklist Check|
|lsrpaf|Install mod_rpaf to set correct client IP behind a proxy.|
|lsvarnish|Installs Varnish 3.0|
|lsvhost|Add an Apache virtual host|
|lsvsftpd|Installs/configures vsftpd|
|lswebmin|Install Webmin on this server|
|lswhatis|Output the script that would be run with a specific command.|
|lswordpress|Install Wordpress on this server|

Enjoy!
