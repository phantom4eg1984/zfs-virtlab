# 1. Определить алгоритм с наилучшим сжатием.
 - Определить какие алгоритмы сжатия поддерживает zfs (gzip gzip-N, zle lzjb, lz4);
 - Создать 4 файловых системы на каждой применить свой алгоритм сжатия;
 - Для сжатия использовать либо текстовый файл либо группу файлов:
скачать файл “Война и мир” и расположить на файловой системе wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8, либо скачать файл ядра распаковать и расположить на файловой системе.

Создал виртуальную машину. Ссылок на vagrant файл в личном кабинете к домашнему заданию по этой теме я не нашел, поэтому воспользовался файлом который демонстрировался на уроке.
Запустил виртуальную машину командой vagrant up client. Установил zfs скриптом zfs-mod.sh, скрипт был создан на основе тех команд которые давались на уроке.

Предварительно я добавил 8 дисков в систему для выполнения заданий. 
Проверяем что все диски присутствуют в системе:
[root@client ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.5G  0 disk 
|-sda1   8:1    0    2G  0 part [SWAP]
`-sda2   8:2    0 17.6G  0 part /
sdb      8:16   0    1G  0 disk 
sdc      8:32   0    1G  0 disk 
sdd      8:48   0    1G  0 disk 
sde      8:64   0    1G  0 disk 
sdf      8:80   0    1G  0 disk 
sdg      8:96   0    1G  0 disk 
sdh      8:112  0    1G  0 disk 
sdi      8:128  0    1G  0 disk 

Создадим 4 одинаковых пула, в каждом пуле будет по 2 диска в mirror:
[root@client ~]# zpool create zfspool1 mirror /dev/sd{b,c}
[root@client ~]# zpool create zfspool2 mirror /dev/sd{d,e}
[root@client ~]# zpool create zfspool3 mirror /dev/sd{f,g}
[root@client ~]# zpool create zfspool4 mirror /dev/sd{h,i}

Проверим что у нас все получилось:
[root@client ~]# zpool list
NAME       SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zfspool1   960M   100K   960M        -         -     0%     0%  1.00x    ONLINE  -
zfspool2   960M   100K   960M        -         -     0%     0%  1.00x    ONLINE  -
zfspool3   960M   100K   960M        -         -     0%     0%  1.00x    ONLINE  -
zfspool4   960M   100K   960M        -         -     0%     0%  1.00x    ONLINE  -

[root@client ~]# zpool status
  pool: zfspool1
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	zfspool1    ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0

errors: No known data errors

  pool: zfspool2
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	zfspool2    ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdd     ONLINE       0     0     0
	    sde     ONLINE       0     0     0

errors: No known data errors

  pool: zfspool3
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	zfspool3    ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdf     ONLINE       0     0     0
	    sdg     ONLINE       0     0     0

errors: No known data errors

  pool: zfspool4
 state: ONLINE
config:

	NAME        STATE     READ WRITE CKSUM
	zfspool4    ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdh     ONLINE       0     0     0
	    sdi     ONLINE       0     0     0

errors: No known data errors

Установим свой алгоритм компрессии для каждого из пулов:
[root@client ~]# zfs set compression=gzip zfspool1
[root@client ~]# zfs set compression=zle zfspool2
[root@client ~]# zfs set compression=lz4 zfspool3
[root@client ~]# zfs set compression=lzjb zfspool4

Проверим что компрессия была установлена:
[root@client ~]# zfs get all | grep compress
zfspool1  compressratio         1.00x                  -
zfspool1  compression           gzip                   local
zfspool1  refcompressratio      1.00x                  -
zfspool2  compressratio         1.00x                  -
zfspool2  compression           zle                    local
zfspool2  refcompressratio      1.00x                  -
zfspool3  compressratio         1.00x                  -
zfspool3  compression           lz4                    local
zfspool3  refcompressratio      1.00x                  -
zfspool4  compressratio         1.00x                  -
zfspool4  compression           lzjb                   local
zfspool4  refcompressratio      1.00x                  -

Загружаем файл на каждый созданный пул для проверки сжатия:
for i in {1..4}; do wget -P /zfspool$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done

Проверяем размер файла и сравниваем:
[root@client zfspool1]# du -s /zfspool*
11059	/zfspool1
39927	/zfspool2
17977	/zfspool3
22029	/zfspool4

[root@client zfspool1]# zfs list
NAME       USED  AVAIL     REFER  MOUNTPOINT
zfspool1  11.0M   821M     10.8M  /zfspool1
zfspool2  39.2M   793M     39.0M  /zfspool2
zfspool3  17.7M   814M     17.6M  /zfspool3
zfspool4  21.7M   810M     21.5M  /zfspool4

Как оказалось наилучий алгоритм сжатия для файлов такого типа оказался у gzip.

# 2.Определить настройки pool’a.
загрузить архив с файлами локально. https://drive.google.com/open?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Распаковать.
С помощью команды zfs import собрать pool ZFS;
Командами zfs определить настройки:
размер хранилища;
тип pool;
значение recordsize;
какое сжатие используется;
какая контрольная сумма используется.

Для выполнения задания номер 2 нам потребуется скачать архив с файлами и распаковать его:
[root@client zfsexport]# wget -O files --no-check-certificate 'https://drive.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg'

[root@client zfsexport]# tar zxvf files

[root@client zpoolexport]# ll
total 1024000
-rw-r--r--. 1 root root 524288000 May 15  2020 filea
-rw-r--r--. 1 root root 524288000 May 15  2020 fileb

Проверяем файлы которые будем импортировать:
[root@client zfsexport]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
	(Note that they may be intentionally disabled if the
	'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
	some features will not be available without an explicit 'zpool upgrade'.
 config:

	otus                              ONLINE
	  mirror-0                        ONLINE
	    /zfsexport/zpoolexport/filea  ONLINE
	    /zfsexport/zpoolexport/fileb  ONLINE

Импортируем пул:
[root@client zfsexport]# zpool import -d zpoolexport/ otus

Проверяем статус пула:
[root@client zfsexport]# zpool status otus
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
	The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
	the pool may no longer be accessible by software that does not support
	the features. See zpool-features(7) for details.
config:

	NAME                              STATE     READ WRITE CKSUM
	otus                              ONLINE       0     0     0
	  mirror-0                        ONLINE       0     0     0
	    /zfsexport/zpoolexport/filea  ONLINE       0     0     0
	    /zfsexport/zpoolexport/fileb  ONLINE       0     0     0

Определяем настройки пула и файловой системы:
[root@client zfsexport]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      13735965857555860167           -
otus  autotrim                       off                            default
otus  compatibility                  off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
otus  feature@redaction_bookmarks    disabled                       local
otus  feature@redacted_datasets      disabled                       local
otus  feature@bookmark_written       disabled                       local
otus  feature@log_spacemap           disabled                       local
otus  feature@livelist               disabled                       local
otus  feature@device_rebuild         disabled                       local
otus  feature@zstd_compress          disabled                       local
otus  feature@draid                  disabled                       local

[root@client zfsexport]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default

Таким образом мы определили:
Размер хранилища 480M
Значение recordsize: 128K
Какое сжатие используется: 1.00x
Какая контрольная сумма используется: sha256

# 3. Найти сообщение от преподавателей:
Скачиваем файл:
wget -O otus_task2.file --no-check-certificate 'https://drive.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG'

Восстанавилваем файлы из нашего файла который мы скачали:
[root@client ~]# zfs receive otus/snapshot < otus_task2.file

Находим файл с именем secret_message:
[root@client task1]# find /otus/snapshot -name "secret_message"

Находим секретное сообщение:
[root@client file_mess]# cat secret_message 
https://github.com/sindresorhus/awesome
