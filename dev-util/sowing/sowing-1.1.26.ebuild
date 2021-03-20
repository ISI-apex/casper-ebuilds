# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Tools for documenting and improving portability"
HOMEPAGE="http://wgropp.cs.illinois.edu/projects/software/sowing/"
SRC_URI="http://wgropp.cs.illinois.edu/projects/software/sowing/${PN}.tar.gz -> ${P}.tar.gz"

SLOT="0"
LICENSE="GPL"
KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
IUSE=""

RDEPEND="
	dev-lang/perl
	"
DEPEND="${RDEPEND}"

src_configure() {
	econf --datadir=${EPREFIX}/usr/share/sowing
}

src_compile() {
	# Parallel build was observed to fail
	emake -j1
}

src_install() {
	emake prefix="${ED}"/usr datadir="${ED}/usr/share/sowing" install
}
