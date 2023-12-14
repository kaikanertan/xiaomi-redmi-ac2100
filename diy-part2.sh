#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

function pull_from_github()
{
	echo "+++++++++++++++++++++++++++++++++++++++++"
	echo -e "\033[35m use git get source from https://github.com/$1/$2 \033[0m"
	if [ ! -d "./package/$2" ]; then
		echo -e "\033[36m pull $2 source \033[0m"
		if [ $# -lt 3 ]; then
			git clone --depth 1 https://github.com/$1/$2 package/$2
		else
			git clone --depth 1 -b $3 https://github.com/$1/$2 package/$2
		fi
	else
		cd ./package/$2
		echo -e "\033[36m udapte $2 source \033[0m"
		git pull
		if [ $? -ne 0 ]; then
				echo -e "\033[31m pull $2 source failed \033[0m"
		else
				echo "surcessful at $(date) " >../../../$mytarget-update/$2
		fi
		cd ../../
	fi
	if [ ! -d "./package/$2" ]; then
		echo "------------------------------------------"
		echo -e "\033[31m get source $2 failed \033[0m"
		echo "------------------------------------------"
	fi
}

# 添加额外软件包
pull_from_github tty228 luci-app-adguardhome
pull_from_github tty228 luci-app-serverchan openwrt-18.06
pull_from_github esirplayground luci-app-poweroff
pull_from_github pymumu luci-app-smartdns lede
pull_from_github_svn xiaorouji openwrt-passwall-packages/trunk pdnsd-alt

# 流量监控
pull_from_github_svn haiibo packages/trunk luci-app-wrtbwmon
pull_from_github_svn haiibo packages/trunk wrtbwmon
# Themes
pull_from_github kiddin9 luci-theme-edge
pull_from_github jerrykuku luci-theme-argon
pull_from_github jerrykuku luci-app-argon-config 
pull_from_github thinktip luci-theme-neobird
pull_from_github xiaoqingfengATGH luci-theme-infinityfreedom


# 在线用户
pull_from_github_svn haiibo packages/trunk luci-app-onliner

grep -n "refresh_interval=2s" package/lean/default-settings/files/zzz-default-settings
if [ $? -ne 0 ]; then
	sed -i '/bin\/sh/a\uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
	sed -i '/nlbwmon/a\uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
fi

if [ -d "package/luci-app-onliner/root/usr/share/onliner" ]; then
	chmod -R 755 package/luci-app-onliner/root/usr/share/onliner/*
fi

# 修改版本为编译日期
grep "by Hwliu" package/lean/default-settings/files/zzz-default-settings
if [ $? -ne 0 ]; then
	date_version=$(date +"%Y.%m.%d")
	orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
	sed -i "s/${orig_version}/R${date_version} by Hwliu/g" package/lean/default-settings/files/zzz-default-settings
else
	date_version=$(date +"%Y.%m.%d")
	sed -i "s/'R2.*by Hwliu/'R${date_version} by Hwliu/g" package/lean/default-settings/files/zzz-default-settings
fi

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/luci\.mk/include \$(TOPDIR)\/feeds\/luci\/luci\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/lang\/golang\/golang\-package\.mk/include \$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang\-package\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHREPO/PKG_SOURCE_URL:=https:\/\/github\.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload\.github\.com/g' {}

# 删除主题强制默认
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

