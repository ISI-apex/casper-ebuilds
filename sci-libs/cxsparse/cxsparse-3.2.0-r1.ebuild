# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

SUITESPARSE_VER=5.7.1
SUITESPARSE_COMP=CXSparse

inherit suitesparse

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"

DEPEND=">=sci-libs/suitesparseconfig-${SUITESPARSE_VER}"
RDEPEND="${DEPEND}"
