# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# TODO: the upstream was renated to openpmix

EAPI=7

EGIT_REPO_URI="https://github.com/openpmix/openpmix.git"
SNAPSHOT_POS=4

inherit git-r3 conf-overlay snapshot

DESCRIPTION="Reference implementation of the Process Management Interface Exascale (PMIx)"
HOMEPAGE="https://openpmix.org/"

if [[ ${PV} == *9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
fi

# TODO: confirm that openmpi complains, and needs rebuild
SLOT="0/$(ver_cut 1-2)"
LICENSE="BSD"
IUSE="debug +munge +hwloc"

RDEPEND="
	dev-libs/libevent:0=
	sys-libs/zlib:0=
	hwloc? ( sys-apps/hwloc )
	munge? ( sys-auth/munge )
	"
DEPEND="${RDEPEND}"

CONF_OVERLAY_FILES=("etc/pmix-mca-params.conf")

src_prepare() {
	default
	./autogen.pl || die
}

src_configure() {
	econf \
		$(use_enable debug) \
		$(use_with munge munge ${EPREFIX}/usr) \
		$(use_with hwloc hwloc ${EPREFIX}/usr) \
		--with-libevent=${EPREFIX}/usr
}

src_install() {
	default
	conf-overlay_src_install
	snapshot_src_install
}
