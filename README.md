# jenkins.example.com

Copycat of [ci.FreeBSD.org](https://ci.freebsd.org) to be migrated to Buildbot.

Sources:

- <https://wiki.freebsd.org/Jenkins>
- <https://wiki.freebsd.org/Jenkins/Architecture>
- <https://wiki.freebsd.org/Jenkins/Backup>
- <https://wiki.freebsd.org/Jenkins/MachineList>
- <https://wiki.freebsd.org/Jenkins/Maintenance>
- <https://wiki.freebsd.org/Jenkins/Setup>

# Local machine (.cirrus.yml)

Install poudriere-devel:

    # pkg install poudriere-devel

Set the poudriere(8) `ZPOOL` environment variable:

    sed -i "" -E 's/^#?ZPOOL=zroot$/ZPOOL=zroot/' \
        /usr/local/etc/poudriere.conf

Configure `ALLOW_MAKE_JOBS`:

    ALLOW_MAKE_JOBS_PACKAGES="pkg llvm* gcc* node*"

Make the poudriere(8) `DISTFILES_CACHE` directory:

    mkdir -p /usr/ports/distfiles

Create the base jails:

    poudriere jail -c -j jenkins-builder -v 14.0-RELEASE
    poudriere jail -c -j nginx-builder -v 14.0-RELEASE
    poudriere jail -c -j artifact-builder -v 14.0-RELEASE
    poudriere jail -c -j agent-builder -m git+https -v main -K GENERIC-NODEBUG
    poudriere jail -c -j ci -m git+https -v main -K GENERIC-NODEBUG

> [!NOTE]
> Suggest to re@:
> Generate a `GENERIC-NODEBUG` kernel image for `-CURRENT`.

To update the jails:

    poudriere jail -u -j <jail_name>

Create the ports trees:

    QUARTERLY_BRANCH=$(date +%YQ)$((($(date +%-m)-1)/3+1))
    poudriere ports -c -U https://git.freebsd.org/ports.git -B $QUARTERLY_BRANCH \
        -p quarterly
    poudriere ports -c -U https://git.freebsd.org/ports.git -B main -p latest

To update the port:

    poudriere ports -u -p quarterly
    poudriere ports -u -p latest

> [!NOTE]
> Suggest to portmgr@ (#274865):
>
>     git symbolic-ref refs/heads/quarterly refs/heads/<QUARTERLY_BRANCH_NAME>
>     git symbolic-ref refs/heads/latest refs/heads/main

Clone this repo:

    git clone https://github.com/jlduran/jenkins.git

Change directory:

    cd jenkins

Build the ports:

    poudriere bulk -j jenkins-builder -b latest -p latest -f pkglist.jenkins
    poudriere bulk -j nginx-builder -b quarterly -p quarterly -f pkglist.nginx
    poudriere bulk -j artifact-builder -b quarterly -p quarterly -f pkglist.artifact
    poudriere bulk -j agent-builder -b latest -p latest -f pkglist.agent
    poudriere bulk -j ci -b latest -p latest -f pkglist.ci

Create the artifacts directory:

    mkdir artifacts

Create a jail environment (JE) or boot environment (BE) for each machine
accordingly:

    poudriere image -t zfs+send -j jenkins-builder -s 2G -p latest -n jenkins \
        -f pkglist.jenkins -c overlaydir.jenkins -B generate-je.sh -o artifacts
    poudriere image -t zfs+send -j nginx-builder -s 1G -p quarterly -n nginx \
        -f pkglist.nginx -c overlaydir.nginx -B generate-je.sh -o artifacts
    poudriere image -t zfs+send -j artifact-builder -s 4G -p quarterly -n artifact \
        -f pkglist.artifact -c overlaydir.artifact -B generate-je.sh -o artifacts
    poudriere image -t zfs+send -j agent-builder -s 4G -p latest -n agent \
        -f pkglist.agent -c overlaydir.agent -o artifacts

The streams are created under `artifacts`.

Import the JEs:

    cat artifacts/jenkins.full.zfs | jectl import jenkins
    cat artifacts/nginx.full.zfs | jectl import nginx
    cat artifacts/artifact.full.zfs | jectl import artifact

Or

Update the JEs and BEs:

    poudriere image -t zfs+send+be -j jenkins-builder -s 2G -p latest -n jenkins \
        -f pkglist.jenkins -c overlaydir.jenkins -B generate-je.sh -o artifacts
    poudriere image -t zfs+send+be -j nginx-builder -s 1G -p quarterly -n nginx \
        -f pkglist.nginx -c overlaydir.nginx -B generate-je.sh -o artifacts
    poudriere image -t zfs+send+be -j artifact-builder -s 4G -p quarterly -n artifact \
        -f pkglist.artifact -c overlaydir.artifact -o artifacts
    poudriere image -t zfs+send+be -j agent-builder -s 4G -p latest -n agent \
        -f pkglist.agent -c overlaydir.agent -o artifacts
    poudriere image -t zfs+send+be -j ci -s 4G -p latest -n ci \
        -f pkglist.ci -o artifacts

Import the JEs or BEs:

    cat artifacts/jenkins.je.zfs | jectl import jenkins.$(date +%s)
    cat artifacts/nginx.je.zfs | jectl import nginx.$(date +%s)
    cat artifacts/artifact.je.zfs | jectl import artifact.$(date +%s)
    cat artifacts/ci.*.zfs | scripts/sync-be/sync-be \
        ci.$(date +%s) bootenv_config.ci

Activate the JEs:

    jectl activate jenkins jenkins.<timestamp>
    jectl activate nginx nginx.<timestamp>
    jectl activate artifact artifact.<timestamp>

> [!NOTE]
> Here is the layout:
>
>     zroot/JAIL/jailname/jename
>     zroot/JE/jename
>
> The `config` dataset is likely to be renamed (NanoBSD inspired?).

# ci

The `ci` machine will contain two persistent VMs, `jenkins14`
and `jenkins15`...

## jenkins13

Is a VM that contains two persistent jails: `jenkins` and `nginx`,
and one ephemeral jail `admin`, that performs administrative tasks,
such as renewing Let's Encrypt certificates...

### jenkins

Is a jail that runs the Jenkins built-in node.
It is updated using the jenkins JE.

Additional plugins:

- https://plugins.jenkins.io/envinject/
- https://plugins.jenkins.io/postbuildscript/

### nginx

Is a jail that contains the reverse proxy for `jenkins`.
It is updated using the nginx JE.


## agent

Is a VM or a bare-metal machine that runs a Jenkins agent.  If it is a VM,
it can only have the labels `image_builder`, `jailer` and `jailer_fast`.
Bare-metal machines can additionally have the `bhyve_host`,
`bhyve_host_net`, `vmhost_bhyve`, and `vmhost_qemu`.

Create `jenkins` dataset

    zfs create -o mountpoint=/jenkins zroot/jenkins
    zfs create zroot/jenkins/jails
    zfs create zroot/jenkins/workspace

Create `jenkins` group

    pw group add jenkins -g 5213

Create `jenkins` user with `/jenkins` as home and `/bin/sh` as shell

    pw useradd jenkins -d "/jenkins" -w no -u 5213 -g 5213 -s "/bin/sh" -c "Jenkins CI"
    chown jenkins:jenkins /jenkins /jenkins/workspace

Take a snapshot of an empty state

    zfs snapshot zroot/jenkins/jails@empty
    zfs snapshot zroot/jenkins/workspace@empty

Setup a repository mirror at `/home/git`

    mkdir -p /home/git
    cd /home/git
    git clone --mirror https://git.FreeBSD.org/doc.git
    git clone --mirror https://git.FreeBSD.org/src.git

    crontab -e
    0,20,40 * * * * cd /home/git/doc.git && git fetch -q --tags
    0,20,40 * * * * cd /home/git/src.git && git fetch -q --tags

## artifact

Is a VM that holds the build artifacts for consuption of downstream
builds or tests.

Create an `artifact` dataset for the jail

    zfs create -o mountpoint=/artifact zroot/artifact

Create `artifact` group

    pw group add artifact -g 1000

Create an `artifact` user with `/home/artifact` as home (null-mounted
from /artifact) and login disabled

    pw useradd artifact -w no -u 1000 -g 1000 -s "" -c "artifact owner"

Create a pure-ftpd user

    pure-pw useradd
    pure-pw mkdb

TODO:
```
08:40:45 FTP: Connecting from host [lancelot.nyi.freebsd.org]
08:40:45 FTP: Connecting with configuration [artifact.ci.freebsd.org] ...
08:40:55 FTP: Disconnecting configuration [artifact.ci.freebsd.org] ...
08:40:55 FTP: Transferred 1 file(s)
08:40:55 [PostBuildScript] - [INFO] Executing post build scripts.
08:40:55 [FreeBSD-stable-12-i386-testvm] $ /bin/sh -xe /tmp/jenkins2292227860671522306.sh
08:40:55 + ./freebsd-ci/artifact/post-link.py
08:40:55 Post link: {'job_name': 'FreeBSD-stable-12-i386-testvm', 'commit': '71f147c60771fb4d6cbab2833c1206e007305044', 'branch': 'stable-12', 'target': 'i386', 'target_arch': 'i386', 'link_type': 'latest_testvm'}
08:40:55 "Link created: stable-12/latest_testvm/i386/i386 -> ../../71f147c60771fb4d6cbab2833c1206e007305044/i386/i386\n"
08:40:55 [PostBuildScript] - [INFO] Executing post build scripts.
08:40:55 [FreeBSD-stable-12-i386-testvm] $ /bin/sh -xe /tmp/jenkins16091965111824414326.sh
08:40:55 + sh freebsd-ci/scripts/jail/clean.sh
08:40:55 clean jail FreeBSD-stable-12-i386-testvm
08:42:03 Triggering a new build of FreeBSD-stable-12-i386-test
08:42:03 Finished: SUCCESS
```

#### acme.sh

Given we use the DNS API and need a key for updating the records, we
generate the certificates on the host, as we do not want DNS
keys/credentials on every jail.  The proposed procedure is the
following:

    # Place your DNS keys in either (if you have bind9 installed or not)
    /var/db/acme/.acme.sh
    /etc/unbound -> /var/unbound
    /usr/local/etc/named -> /var/named/usr/local/etc/namedb
    # (acme:acme) 0400

In `/var/db/acme/.acme.sh/account.conf`, set accordingly, for example

    NSUPDATE_SERVER="dns.example.com"
    NSUPDATE_KEY="/var/db/acme/.acme.sh/Kns1.example.com.+123+45678.key"

Or set

    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY

for example, if you plan to use the `dns_aws` API.

Grant sudo privileges to `acme`, for reloading nginx

    umask 7337; echo \
    'acme ALL=(ALL:ALL) NOPASSWD: /usr/sbin/service -j * nginx forcereload' > \
    /usr/local/etc/sudoers.d/acme

Use Let's Encrypt by default

    su -l acme -c "acme.sh --set-default-ca --server letsencrypt"

Issue the certificates

    su -l acme -c "acme.sh --issue --dns dns_nsupdate -d ${jail}.example.com"

Deploy to the jails

    mkdir -m 0700 -p /${jail_name}/usr/local/etc/ssl/private # for keys  || acme-private
    mkdir -m 0755 -p /${jail_name}/usr/local/etc/ssl/certs   # for certs || acme-certs
    chown acme:acme /${jail_name}/usr/local/etc/ssl/private \
    /${jail_name}/usr/local/etc/ssl/certs

    su -l acme -c "acme.sh --install-cert -d ${jail}.example.com --ecc \
    --fullchain-file /${jail_name}/usr/local/etc/ssl/certs/${jail}.example.com.crt \
    --key-file /${jail_name}/usr/local/etc/ssl/private/${jail}.example.com.key \
    --reloadcmd 'sudo service -j $jail_name nginx forcereload'"

Install a crontab for `acme`

    mkdir -p /usr/local/etc/cron.d
    cp /usr/local/share/examples/acme.sh/acme.sh-cron.d /usr/local/etc/cron.d/acme

and modify accordingly.

Configure log rotation by uncommenting
`/usr/local/etc/newsyslog.conf.d/acme.sh.conf`, and issuing

    newsyslog -NC
