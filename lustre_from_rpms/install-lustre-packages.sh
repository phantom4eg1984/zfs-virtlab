selinuxenabled && setenforce 0
 
cat >/etc/selinux/config<<__EOF
SELINUX=disabled
SELINUXTYPE=targeted
__EOF
 
 
yum-config-manager --add-repo=https://downloads.whamcloud.com/public/lustre/lustre-2.12.4/el7/patchless-ldiskfs-server/
yum-config-manager --add-repo=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7/
yum install -y --nogpgcheck lustre kmod-lustre-osd-ldiskfs

