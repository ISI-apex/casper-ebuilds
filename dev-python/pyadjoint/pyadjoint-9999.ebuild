# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

EGIT_REPO_URI="https://github.com/dolfin-adjoint/pyadjoint.git"
EGIT_SUBMODULES=()

PYTHON_COMPAT=( python3_{6,7,8} )

inherit distutils-r1 eutils git-r3

if [[ "$(ver_cut 4 ${PV})" = "p" ]]
then
	MY_D="$(ver_cut 5 ${PV})"
	EGIT_COMMIT_DATE="${MY_D:0:4}-${MY_D:4:2}-${MY_D:6:2}"
	KEYWORDS="~amd64 ~amd64-linux ~ppc64 ~ppc64-linux"
else # live
	KEYWORDS=""
fi

DESCRIPTION="The algorithmic differentation tool pyadjoint and add-ons."
HOMEPAGE="https://github.com/dolfin-adjoint/pyadjoint"

LICENSE="LGPL"
SLOT="0"
IUSE="test moola visualisation meshing"

# TODO: testing requires fenics (and, with HDF5)
DEPEND="
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )
	"
# TODO: moola, meshio, pygmsh
RDEPEND="${DEPEND}
	>=dev-python/scipy-1.0[${PYTHON_USEDEP}]
	moola? ( >=dev-python/moola-0.1.6 )
	visualisation? ( sci-libs/tensorflow
				>=dev-python/protobuf-python-3.6.0
				dev-python/networkx
				dev-python/pygraphviz )
	meshing? ( dev-python/pygmsh
			dev-python/meshio )
	"
distutils_enable_tests pytest
