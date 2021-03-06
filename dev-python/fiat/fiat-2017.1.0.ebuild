# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_4 python3_5 python3_6 python3_8 )

inherit distutils-r1

DESCRIPTION="FInite element Automatic Tabulator"
HOMEPAGE="https://bitbucket.org/fenics-project/fiat"
SRC_URI="https://bitbucket.org/fenics-project/fiat/downloads/${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~ppc64 ~ppc64-linux"
IUSE=""

DEPEND=""
RDEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
	"
