set -e

# Download maven 3.6.3
wget https://www-us.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz -P /tmp

# Untar to /opt
tar xf /tmp/apache-maven-*.tar.gz -C /opt

# Install the alternative version for the mvn in your system
sudo update-alternatives --install /usr/bin/mvn mvn /opt/apache-maven-3.6.3/bin/mvn 363

# Check if your configuration is ok. You may use your current or the 3.6.3 whenever you wish, running the command below.
sudo update-alternatives --config mvn
