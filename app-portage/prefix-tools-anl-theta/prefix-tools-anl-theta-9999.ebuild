# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PREFIX_TOOLS_CLUSTER="anl-theta"
inherit prefix-tools conf-overlay

DEPEND="$(prefix-tools_get_conflicts)"

CONF_OVERLAY_FILES=(
	"etc/openmpi-mca-params.conf"
)

src_install() {
	prefix-tools_src_install

	# For binary tools we install into a folder that does not have the
	# cluster in its name, but for these library-like files, let's keep
	# the install path consistent with the path in the upstream repo.
	insinto /usr/share/prefix-tools/clusters/${PREFIX_TOOLS_CLUSTER}
	doins -r ${PREFIX_TOOLS_CLUSTER}/make
}
