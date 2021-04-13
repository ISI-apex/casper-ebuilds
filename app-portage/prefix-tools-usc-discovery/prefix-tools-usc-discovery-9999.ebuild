# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PREFIX_TOOLS_CLUSTER="usc-discovery"
inherit prefix-tools snapshot

if [[ ${PV} == *9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux"
fi

DEPEND="$(prefix-tools_get_conflicts)"

src_install() {
	prefix-tools_src_install
	snapshot_src_install
}
