#!/bin/sh
#set -e

MYVER=5.1.59
Q4MVER=0.9.5

CDIR=$(cd $(dirname $0) && pwd)
mkdir -p /usr/local/src
cd /usr/local/src

if [ ! -f mysql-$MYVER.tar.gz ]; then
    wget http://downloads.mysql.com/archives/mysql-5.1/mysql-$MYVER.tar.gz
fi

if [ -d mysql-$MYVER ]; then
    rm -rf mysql-$MYVER
fi
tar zxf mysql-$MYVER.tar.gz
cd mysql-$MYVER
./configure \
    --prefix=/usr/local/q4m \
    --with-mysqld-ldflags="-static" \
    --with-client-ldflags="-static" \
    --enable-assembler \
    --enable-thread-safe-client \
    --with-charset=utf8 \
    --with-zlib-dir=bundled \
    --with-big-tables \
    --with-mysqld-user=nobody \
    --with-pic \
    --with-extra-charsets=all \
    --with-readline \
    --without-debug \
    --enable-shared \
    --with-fast-mutexes \
    --with-comment="Q4M" \
    --with-server-suffix="-q4m" \
    --with-unix-socket-path="/tmp/mysql_q4m.sock" \
    --with-tcp-port=13306 \
    --with-plugins=none \
    --without-plugin-daemon_example \
    --without-plugin-ftexample \
    --without-plugin-archive \
    --without-plugin-blackhole \
    --without-plugin-example \
    --without-plugin-federated \
    --without-plugin-innobase \
    --without-plugin-innodb_plugin \
    --without-docs \
    --without-man
make
make install

mkdir -p /usr/local/q4m/etc
cp $CDIR/my.cnf /usr/local/q4m/etc

mkdir -p /usr/local/q4m/var
pw useradd q4m -s /sbin/nologin
chown -R q4m /usr/local/q4m
/usr/local/q4m/bin/mysql_install_db --defaults-file=/usr/local/q4m/etc/my.cnf
chmod 755 /usr/local/q4m/var

cp $CDIR/q4m.init /usr/local/etc/rc.d/q4m-server
chmod 755 /usr/local/etc/rc.d/q4m-server
echo "" >> /etc/rc.conf
echo "q4m_enable=\"YES\"" >> /etc/rc.conf
/usr/local/etc/rc.d/q4m-server start

cd /usr/local/src
if [ ! -f q4m-$Q4MVER.tar.gz ]; then
    wget http://q4m.kazuhooku.com/dist/q4m-$Q4MVER.tar.gz
fi
if [ -d q4m-$Q4MVER ]; then
    rm -rf q4m-$Q4MVER
fi
tar zxf q4m-$Q4MVER.tar.gz
cd q4m-$Q4MVER
CPPFLAGS="-I/usr/local/q4m/include/mysql" CFLAGS="-L/usr/local/q4m/lib/mysql" ./configure \
    --with-mysql=/usr/local/src/mysql-$MYVER \
    --prefix=/usr/local/q4m
make
mkdir -p /usr/local/q4m/lib/mysql/plugin
cp src/.libs/libqueue_engine.so /usr/local/q4m/lib/mysql/plugin/
cat support-files/install.sql | /usr/local/q4m/bin/mysql --defaults-file=/usr/local/q4m/etc/my.cnf -S /tmp/mysql_q4m.sock



