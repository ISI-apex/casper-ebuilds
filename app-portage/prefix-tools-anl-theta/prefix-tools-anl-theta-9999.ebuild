# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PREFIX_TOOLS_CLUSTER="anl-theta"
inherit prefix-tools conf-overlay snapshot

if [[ ${PV} == *9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux"
fi

DEPEND="$(prefix-tools_get_conflicts)"

CONF_OVERLAY_FILES=(
	"etc/openmpi-mca-params.conf"
)

src_install() {
	prefix-tools_src_install
}
