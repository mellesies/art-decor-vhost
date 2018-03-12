#!/bin/bash
echo '*************************************************************'
echo '*            Welcome to the ART-DECOR installer!            *'
echo '*************************************************************'
echo 'This script intends to make the installation a little easier,'
echo 'although several manual steps are still included.'
echo 'This script needs to run as root and will store any files in'
echo '/root'

export TOMCAT_HOME=/var/lib/tomcat7
export EXIST_HOST=debian
export ASSETS=/root/assets

apt-get update
apt-get install -y dirmngr

# Automatically accept license for Java8
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

# directory man1 is required for installing java8
mkdir -p /usr/share/man/man1

cp $ASSETS/webupd8team-java.list /etc/apt/sources.list.d/
cp $ASSETS/debian-jessie.list /etc/apt/sources.list.d/

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
apt-get update
apt-get install -y --allow-unauthenticated oracle-java8-installer oracle-java8-set-default tomcat7
apt-get install -y sudo vim curl patch python wget


# Download eXist-db
if [ ! -f $ASSETS/eXist-db-setup-2.2-rev0000.jar ]; then
    echo "Downloading eXist-db"
    wget -P $ASSETS http://downloads.sourceforge.net/project/artdecor/eXist-db/eXist-db-setup-2.2-rev0000.jar
fi

# Base URL for downloading exist packages with ART-DECOR
BASE_URL="http://decor.nictiz.nl/apps/public-repo/public/"

# Order is important!
PACKAGES=(
  "ART-1.8.58.xar"
  "DECOR-core-1.8.42.xar"
  "DECOR-services-1.8.35.xar"
  "ART-DECOR-system-services-1.8.23.xar"
  "terminology-1.8.36.xar"
)
    
mkdir -p $ASSETS/exist-packages
for i in "${PACKAGES[@]}"
do
    if [ ! -f $ASSETS/exist-packages/$i ]; then
        echo "Downloading package $i"
        wget -P $ASSETS/exist-packages $BASE_URL$i
    fi
done
    
# Download ART-DECOR
if [ ! -f $ASSETS/art-decor.war ]; then
    echo "Downloading ART-DECOR"
    wget -P $ASSETS http://downloads.sourceforge.net/project/artdecor/Orbeon/art-decor.war
fi


# Install & configure tomcat7, set JAVA_HOME to the Oracle version.
echo 'Configuring tomcat7.'
sed -i '/#JAVA_HOME=/a JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre' /etc/default/tomcat7
patch /etc/tomcat7/server.xml $ASSETS/server.xml.patch

echo "Creating log directory"
mkdir /usr/share/tomcat7/logs
touch /usr/share/tomcat7/logs/art-decor.log
chown tomcat7 /usr/share/tomcat7/logs/art-decor.log
chmod 644 /usr/share/tomcat7/logs/art-decor.log
ln -s /usr/share/tomcat7/logs/art-decor.log /var/log/tomcat7/

echo "Installing the ART-DECOR web archive into tomcat."
mv $ASSETS/art-decor.war $TOMCAT_HOME/webapps

# Start tomcat so it automatically unpacks art-deor.war
service tomcat7 start

# replace localhost with host specified above.
sed -i 's/localhost/'"$EXIST_HOST"'/' $TOMCAT_HOME/webapps/art-decor/WEB-INF/resources/config/properties-local.xml 
sed -i 's/localhost/'"$EXIST_HOST"'/' $TOMCAT_HOME/webapps/art-decor/WEB-INF/resources/page-flow.xml


# Unfortunately eXist-db requires user input during installation. Fortunately
# there's a python script (by Melle) to take care of that :-)
python $ASSETS/install_existdb.py

# Create symlinks
ln -s /usr/local/exist_atp_2.2 /usr/local/exist_atp
ln -s /usr/local/exist_atp/tools/wrapper/logs/ /var/log/exist_wrapper
ln -s /usr/local/exist_atp/webapp/WEB-INF/logs /var/log/exist
ln -s /usr/local/exist_atp/tools/wrapper/bin/exist.sh /etc/init.d/exist

# Create a user, chown the installation and make sure the service is started
# by with the correct uid
adduser --system --group existdb
chown -R existdb:existdb /usr/local/exist_atp*
sed -i '/#RUN_AS_USER=/a RUN_AS_USER=existdb' /usr/local/exist_atp/tools/wrapper/bin/exist.sh

# This fails when started as root!
sudo -u existdb /etc/init.d/exist start

echo "Uploading configuration.xml with nictiz repository to eXist-db"
curl -v -u admin:password --upload-file $ASSETS/configuration.xml http://localhost:8877/rest/db/apps/dashboard/

echo "Uploading xquery script to install packages via http GET"
curl -u admin:password --upload-file $ASSETS/install_exist_pkg.xquery http://localhost:8877/rest/db/system/install/

PACKAGES=(
  "ART-1.8.58.xar"
  "DECOR-core-1.8.42.xar"
  "DECOR-services-1.8.35.xar"
  "ART-DECOR-system-services-1.8.23.xar"
  "terminology-1.8.36.xar"
)

for i in "${PACKAGES[@]}"
do
    echo "Installing eXist-db package '$i'"
    echo
    /usr/local/exist_atp/bin/client.sh -u admin -P password -m /db/system/repo/ -p assets/exist-packages/$i -ouri=xmldb:exist://127.0.0.1:8877/xmlrpc
    curl -u admin:password http://localhost:8877/rest/db/system/install/install_exist_pkg.xquery?pkg=$i
done

# Restart tomcat
service tomcat7 restart