# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_8 )
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 eutils

DESCRIPTION="Unified Form Language for declaration of for FE discretizations"
HOMEPAGE="https://bitbucket.org/fenics-project/ufl/"
SRC_URI="https://bitbucket.org/fenics-project/ufl/downloads/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~ppc64 ~ppc64-linux"
IUSE="test"

DEPEND="
	test? ( $(python_gen_cond_dep \
			'dev-python/pytest[${PYTHON_MULTI_USEDEP}]') )
	"
RDEPEND="${DEPEND}
	$(python_gen_cond_dep \
		'dev-python/numpy[${PYTHON_MULTI_USEDEP}]' \
	)
	"

pkg_postinst() {
	optfeature "Support for evaluating Bessel functions" dev-python/scipy
}
