#!/bin/sh

#[ -z "`grep -o ARMv7.*v7l /proc/cpuinfo`" ] && echo "Your processor is not an ARMv7l; this is not the right repository for you." && exit
#[ -z "`grep -o kongac /tmp/loginprompt`" ] && echo "This is not a Kong K3-AC-ARM build; this is not the right repository for you." && exit

echo "Checking we can reach the repository..."
[ -z "`curl -sfI http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/base/Packages.gz`" ] && echo "Could not download Packages.gz, connectivity problem?" && exit

cd /opt
mkdir -p /opt/etc >/dev/null 2>&1
mkdir -p /opt/var/opkg-lists >/dev/null 2>&1
mkdir -p /opt/usr/bin >/dev/null 2>&1
mkdir -p /opt/var/lock >/dev/null 2>&1
cat > /opt/usr/bin/optware_boottime << 'EOF'
#!/bin/sh
# If we have /jffs/opt but no /opt, then bind mount on startup (does nothing if USB in use)
[ -z "$(grep /opt /proc/mounts)" ] && [ ! -z "$(grep jffs2 /proc/mounts)" ] && [ -d "/jffs/opt" ] && mount --bind /jffs/opt /opt
# Add alias to set desired switched to opkg
echo 'alias opkg="opkg -f /opt/etc/opkg.conf --force-depends"' >>/tmp/root/.profile
# Hack to stop kmod.* postinst scripts, we don't have the /lib/functions.sh anyways
echo 'export IPKG_INSTROOT="/opt"' >>/tmp/root/.profile
echo 'PATH="/opt/usr/bin:/opt/usr/sbin:/opt/bin:/opt/sbin:$PATH"' >>/tmp/root/.profile
#echo 'LD_LIBRARY_PATH="/opt/lib:/opt/usr/lib:$LD_LIBRARY_PATH"' >>/tmp/root/.profile
EOF
chmod 700 /opt/usr/bin/optware_boottime
#cat /opt/usr/bin/optware_boottime | sh
# this is not permanent
alias opkg="opkg -f /opt/etc/opkg.conf --force-depends"
IPKG_INSTROOT=/opt
echo "Making sure we have an initial opkg"
[ -x /opt/bin/opkg ] || cd /opt \
		`/usr/bin/wget https://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/base/opkg_9c97d5ecd795709c8584e972bfdf3aee3a5b846d-8_brcm47xx.ipk -O opkg.ipk` \
		`/bin/mkdir -p /opt/lib` \
		`/usr/bin/wget https://dev.openwrt.org/browser/trunk/package/base-files/files/lib/functions.sh?format=txt -O /opt/lib/functions.sh` \
		EXTB=`tar zxvf opkg.ipk` \
		EXTC=`tar zxvf data.tar.gz` \
		REMOVE=`rm -rf opkg.ipk data.tar.gz control.tar.gz debian-binary` \
		echo "Install complete. You can now use opkg to install additional packages."

[ -x /opt/bin/opkg ] || exit

echo "Creating the opkg config file in /opt/etc/opkg"
cat > /opt/etc/opkg.conf <<EOF
src/gz chaos_calmer_base http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/base
#src/gz chaos_calmer_luci http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/luci
#src/gz chaos_calmer_management http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/management
src/gz chaos_calmer_packages http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/packages
src/gz chaos_calmer_routing http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/routing
src/gz chaos_calmer_telephony http://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/telephony
dest root /opt
dest ram /tmp
lists_dir ext var/opkg-lists
option overlay_root /opt/overlay
arch all 1
arch noarch 1
arch brcm47xx 5
EOF



#echo "Updating opkg itself from new repository"
#opkg --force-reinstall install opkg >/dev/null 2>&1


# this is not permanent, silences kmod-* postinst scripts
export IPKG_INSTROOT="/opt"

echo "You are now ready to install packages using opkg (this session only)."
echo "I've installed a script, optware_boottime, to run on boot and make the opkg settings persistent."
echo "I'll add this to the end of rc_startup in nvram for you."
nvram get rc_startup | grep -v "optware_boottime" > /tmp/rcstartup
echo "/opt/usr/bin/optware_boottime" >> /tmp/rcstartup
nvram set rc_startup="`cat /tmp/rcstartup`"
#rm -f /tmp/rcstartup
#nvram get rc_startup
#echo "Updating opkg lists from new repository"
#[ -x /opt/bin/opkg ] && opkg update
rm -f /opt/etc/opkg/distfeeds.conf
#alias opkg="opkg -f /opt/etc/opkg.conf --force-depends"
/opt/usr/bin/optware_boottime
/opt/bin/opkg -f /opt/etc/opkg.conf update
echo "Minimal setup is complete. You should now have a working opkg."
echo "We have created some aliases in your ~/.profile to make everything work."
echo "Please either 'source .profile' or LOG OUT and LOG IN AGAIN before proceeding."
#echo "Installing libc package to silence dependencies"
#opkg --force-overwrite install https://downloads.openwrt.org/snapshots/trunk/brcm47xx/generic/packages/base/libc_1.1.10-1_brcm47xx.ipk
